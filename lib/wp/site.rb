module WP
  class Site
    include Helper
    attr_accessor :url

    def initialize(url, client, id = nil)
      @url = url
      @client = client
      @id = id
    end

    def id
      @id ||= begin
        log_info("Fetching site id for #{@url}")
        @client.site_id(@url)
      end
    end

    def name
      log_info("Fetching site name for #{@url}")
      @name ||= @client.option_get(@url, "blogname")
    end

    def users
      @users ||= begin
        log_info "Loading users from #{@url}"
        @client.user_list(@url)
      end
    end

    def import_users(users_csv_path)
      log_info "Importing users from #{users_csv_path}"
      @client.user_import(@url, users_csv_path)
    end

    def export_content
      @client.export(@url).tap do |export|
        log_info "Generated export file at #{export}"
      end
    end

    def import_content(export_path, login_map_path)
      log_info "Running content import. This might take a while..."
      @client.import(@url, export_path, login_map_path)
    end

    def menus
      @menus || begin
        log_info "Loading menus for #{@url}"
        @menus = @client.menu_list(@url)
        @menus.each do |menu|
          menu["items"] = @client.menu_item_list(@url, menu["term_id"])
        end
      end
    end

    def assign_menu(menu, location)
      @client.menu_location_assign(@url, menu, location)
    end

    def theme
      @theme ||= @client.theme_current(@url)
    end

    def theme_installed?(theme)
      @client.theme_is_installed(theme)
    end

    def install_theme(theme)
      log_info "Attempting to install theme `#{theme}`"
      @client.theme_install(theme)
    rescue WP::ClientError
      raise WP::CouldNotInstallThemeError
    end

    def activate_theme(theme)
      log_info "Activating theme `#{theme}`"
      @theme = nil
      @client.theme_activate(@url, theme).tap do |result|
        log_info "Theme not activated" unless result
      end
    end

    def theme_mods
      @client.theme_mod_list(url)
    end

    def set_theme_mod(mod, value)
      @client.theme_mod_set(url, mod, value)
    end

    def is_plugin_active?(plugin)
      log_info "Checking status of plugin `#{plugin}`"
      @client.plugin_is_active(url, plugin)
    end

    def enable_plugin(plugin)
      log_info "Enabling plugin `#{plugin}`"
      @client.plugin_activate(url, plugin)
    end

    def widgets(sidebar)
      @client.widget_list(url, sidebar["id"])
      # @widgets ||= {}.tap do |widgs|
      # sidebars.each do |s|
      #   pp @client.widget_list(url, s["id"])
      # end
    end

    def move_widget(widget, sidebar: nil, position: nil)
      log_info "Moving widget `#{widget["id"]}` to sidebar `#{sidebar["id"]}`"

      sidebar_id = sidebar ? sidebar["id"] : nil
      @client.widget_move(url, widget["id"], sidebar_id, position)
    end

    def sidebars
      @sidebars ||= @client.sidebar_list(url)
    end

    def delete_post(id)
      log_info "Deleting post ID #{id}"
      @client.post_delete(@url, id)
    end

    def self.create(slug, title, admin_email, client)
      log_info "Creating new site #{title} (#{slug} - #{admin_email})"

      site_id = client.site_create(slug, title, admin_email)
      url = client.site_url(site_id)

      log_info "Site created: #{url} (#{site_id})"

      new(url, client, site_id).tap do |site|
        # Delete the first post
        site.delete_post(1)
      end
    rescue WP::ClientError => e
      raise WP::SiteAlreadyExistsError if e.message == "Error: Sorry, that site already exists!"
      raise e
    end

    def self.get_by_slug(slug, client)
      log_info "Loading site for slug #{slug}"
      sites = client.site_list
      site = sites.find { _1["url"].include? slug }
      raise "Can't find site for slug #{slug}" unless site

      new(site["url"], client, site["blog_id"])
    end
  end
end
