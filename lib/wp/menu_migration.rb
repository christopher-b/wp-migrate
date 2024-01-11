module WP
  class MenuMigration
    include Helper

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating menus"
      @old_site.menus.each do |old_menu|
        new_menu = @new_site.menus.find { _1["slug"] == old_menu["slug"] }
        old_menu["locations"].each do |location|
          log_info "Assigning #{new_menu["slug"]} to #{location}"
          @new_site.assign_menu(new_menu["slug"], location)
        end
      end

      log_info "Menu migration complete"
    end
  end
end
