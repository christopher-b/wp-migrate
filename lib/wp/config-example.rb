module WP
  class Config
    class << self
      def ldap
        {
          host: "host",
          port: 636,
          base: "DC=test,DC=com",
          auth: {
            method: :simple,
            username: ENV.fetch("LDAP_USER", ""),
            password: ENV.fetch("LDAP_PASS", "")
          },
          encryption: {
            method: :simple_tls
          }
        }
      end

      def remote_file_dest
        @remote_file_dest ||= ENV.fetch("REMOTE_FILE_DEST", "path/to/remote/files")
      end
    end
  end
end
