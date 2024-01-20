require "thor"
require "wp"

module WP
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "migrate SLUG ADMIN_EMAIL", "Do a complete migration"
    def migrate(slug, admin_email)
      old_url = "http://blog.ocad.ca/wordpress/#{slug}"
      migration = WP::Migration.new(old_url, slug, admin_email)
      migration.start
    end
  end
end
