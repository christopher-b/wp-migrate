module WP
  class ThemeMigration
    include Helper

    DEFAULT_THEME = "generatepress"

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating theme"

      theme = @old_site.theme
      if @new_site.theme_installed?(theme)
        log_info "Theme `#{theme} already installed`"
      else
        log_info "Installing theme `#{theme}`"
        @new_site.install_theme(theme)
      end

      begin
        log_info "Activating theme `#{theme}`"
        @new_site.activate_theme(theme)
      rescue
        log_info "Could not install theme `#{theme}`. Defaulting to `#{DEFAULT_THEME}`"
        @new_site.activate_theme(DEFAULT_THEME)
      end

      log_info "Theme migration complete"
    end
  end
end
