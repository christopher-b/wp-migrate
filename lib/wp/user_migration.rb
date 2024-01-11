require "csv"
require "json"
require "rest-client"

module WP
  class UserMigration
    include Helper

    USER_CSV_FILENAME = "user-export.csv"

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating users from #{@old_site.url} to #{@new_site.url}"
      copy_csv_to_remote(export_csv, USER_CSV_FILENAME)
      import
      log_info "User migration complete"
    end

    def import
      log_info "Starting user import"
      result = @new_site.import_users(user_csv_remote_path)
      log_info result
    end

    def login_map_csv
      # corrected_old_users # Make sure @login_map has been populated
      CSV.generate do |csv|
        column_nanes = %w[old_user_login new_user_login]
        csv << column_nanes
        login_map.to_a.each { csv << _1 }
      end
    end

    private

    def user_csv_remote_path
      File.join(WP::Config.remote_file_dest, "tmp", USER_CSV_FILENAME)
    end

    def export_csv
      @export_csv ||= begin
        log_info "Found #{@old_site.users.size} users; fixing usernames"

        CSV.generate do |csv|
          column_nanes = corrected_old_users.first.keys
          csv << column_nanes
          corrected_old_users.each do |user|
            csv << user.values
          end
        end
      end
    end

    # A hash mapping old-site user logins to new-site SIS IDs
    def login_map
      @login_map ||= ldap_users.values.map { [_1[:samaccountname], (_1[:ocaderpid] || _1[:samaccountname])] }
    end

    # Change user_login from existing to SIS ID
    def corrected_old_users
      @corrected_old_users ||= @old_site
        .users
        .map { |user|
          old_login = user["user_login"]
          ldap_user = ldap_users[old_login]
          unless ldap_user
            log_warn "Unable to find LDAP user for #{old_login}"
            next
          end

          ldap_user.stringify_keys!
          {
            user_email: user["user_email"],
            roles: user["roles"],
            display_name: ldap_user["displayname"],
            user_login: ldap_user["ocaderpid"] || ldap_user["cn"],
            first_name: ldap_user["givenname"],
            last_name: ldap_user["sn"]
          }
        }
        .compact
    end

    def user_logins
      @old_site.users.map { _1["user_login"] }
    end

    def ldap_users
      @ldap_users ||= WP::UserFinder.get_users_for_logins(user_logins)
    end
  end
end
