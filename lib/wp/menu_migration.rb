module WP
  class MenuMigration
    include Helper

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating menus"

      old_menus.each do |old_menu|
        assign_menu_to_locations(
          matching_new_menu(old_menu),
          old_menu["locations"]
        )
      end

      log_info "Menu migration complete"
    end

    def assign_menu_to_locations(menu, locations)
      locations.each do |location|
        log_info "Assigning #{menu["slug"]} to #{location}"
        begin
          @new_site.assign_menu(menu["slug"], location)
        rescue WP::ClientError
          log_warn "Could not assign menu #{menu["slug"]} to #{location}"
        end
      end
    end

    def old_menus
      @old_menus ||= @old_site.menus
    end

    def new_menus
      @new_menus ||= @new_site.menus
    end

    def matching_new_menu(menu)
      new_menus.find { _1["slug"] == menu["slug"] }
    end
  end
end
