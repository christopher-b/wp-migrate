module WP
  class ThemeMigration
    include Helper

    DEFAULT_THEME = "generatepress"

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating theme. Original theme is `#{original_theme}`"

      install_original_theme unless original_theme_installed?
      activate_new_theme
      migrate_mods

      log_info "Theme migration complete"
    end

    def original_theme
      @original_theme ||= @old_site.theme
    end

    def original_theme_installed?
      @original_theme_installed ||= @new_site.theme_installed?(original_theme)
    end

    def install_original_theme
      @new_site.install_theme(original_theme)
      @original_theme_installed = true

      log_info "Theme installed: #{original_theme}"
    rescue WP::CouldNotInstallThemeError => e
      @original_theme_installed = false
      log_warn "Could not install theme #{original_theme}: #{e.message}"
    end

    def theme_to_activate
      original_theme_installed? ? original_theme : DEFAULT_THEME
    end

    def activate_new_theme
      if @new_site.theme == theme_to_activate
        log_info "Theme `#{theme_to_activate}` is already active"
      else
        @new_site.activate_theme(theme_to_activate)
      end
    end

    def migrate_mods
      log_info "Copying theme mods"

      @old_site.theme_mods.each do |mod, value|
        next unless value
        next if value == "=>"
        next if value[0..3] == "    "

        log_info "Setting theme mod #{mod}: #{value}"
        @new_site.set_theme_mod(mod, value)
      end
    end
  end
end
