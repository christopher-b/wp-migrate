module WP
  class Migration
    include Helper

    def initialize(old_url, new_site_slug, admin_email)
      @old_url = old_url
      @new_site_slug = new_site_slug
      @admin_email = admin_email
    end

    def start
      log_info "Initiating migration for #{@old_url}"

      content_migration.login_map_csv = user_migration.login_map_csv

      [
        user_migration,
        file_migration,
        content_migration,
        theme_migration,
        menu_migration
      ].each(&:run)
    end

    def old_site
      @old_site ||= WP::Site.new(@old_url, wp_old)
    end

    def new_site
      @new_site ||= WP::Site.create(@new_site_slug, old_site.name, @admin_email, wp_new)
    rescue WP::SiteAlreadyExistsError
      log_info "Site exists, getting existing site"
      @new_site = WP::Site.get_by_slug(@new_site_slug, wp_new)
    end

    def user_migration
      @user_migration ||= WP::UserMigration.new(old_site, new_site)
    end

    def file_migration
      @file_migration ||= WP::FileMigration.new(old_site, new_site)
    end

    def content_migration
      @content_migration ||= WP::ContentMigration.new(old_site, new_site)
    end

    def theme_migration
      @theme_migration ||= WP::ThemeMigration.new(old_site, new_site)
    end

    def menu_migration
      @menu_migration ||= WP::MenuMigration.new(old_site, new_site)
    end

    def site_name
      @wp_old.option_get "blogname"
    end

    def wp_old
      @wp_old ||= WP::Client.new("@wpmu-old")
    end

    def wp_new
      @wp_new ||= WP::Client.new("@wpmu-new")
    end
  end
end
