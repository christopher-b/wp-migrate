require "net/ldap"

module WP
  class UserFinder
    class << self
      LDAP_USER_ATTRIBUTES = %w[
        userprincipalname
        cn
        samaccountname
        ocaderpid
        givenname
        sn
        displayname
        mail
      ]

      def get_users_for_logins(logins)
        users_by_username = load_users(logins, :samaccountname)
        users_by_sis_id = load_users(logins, :ocaderpid)
        users_by_username.merge users_by_sis_id
      end

      def load_users(logins, field)
        filter = logins
          .map { |login| Net::LDAP::Filter.eq(field, login) }
          .inject(:|)

        result = connection.search(filter: filter, attributes: LDAP_USER_ATTRIBUTES)
        result = Array.wrap(normalize_entry(result))
        result.map { [_1[field], _1] }.to_h
      end

      def connection
        @connection ||= Net::LDAP.new(WP::Config.ldap)
      end

      def normalize_entry(entry)
        case entry
        when Array
          entry.one? ? normalize_entry(entry.first) : entry.map { |child_entry| normalize_entry(child_entry) }
        when Hash
          entry.transform_values { |value| normalize_entry(value) }
        when Net::LDAP::Entry
          normalize_entry(entry.to_h)
        when Net::BER::BerIdentifiedArray
          normalize_entry(entry.to_a)
        when Net::BER::BerIdentifiedString
          entry.to_s
        else
          entry
        end
      end
    end
  end
end
