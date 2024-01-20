module WP
  class WidgetMigration
    include Helper

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating widgets"

      if @old_site.theme != @new_site.theme
        log_info "Theme not synced, skipping"
        return
      end

      inactive = new_sidebars.find { _1["id"] == "wp_inactive_widgets" }

      # new_sidebars.each do |ns|
      #   pp "Sidebar #{ns}"
      #   @new_site.widgets(ns).each do |w|
      #     pp "W: #{w}"
      #   end
      # end

      new_sidebars.each do |new_sidebar|
        log_info "Syncing sidebar `#{new_sidebar["name"]}`"

        next if new_sidebar["id"] == "wp_inactive_widgets"

        old_sidebar = old_sidebars.find { _1["id"] == new_sidebar["id"] }
        old_widgets = @old_site.widgets(old_sidebar)
        new_widgets = @new_site.widgets(new_sidebar)

        # Remove widgets that are not present in old_sidebar
        new_widgets.each do |new_widget|
          unless old_widgets.find { _1["id"] == new_widget["id"] }
            log_info "Removing `#{new_widget["id"]}` from `#{new_sidebar}`"
            @new_site.move_widget(new_widget, sidebar: inactive)
          end
        end

        # Add widgets not present in new_sidebar
        old_widgets.each do |old_widget|
          unless new_widgets.find { _1["id"] == old_widget["id"] }
            begin
              log_info "Adding `#{old_widget["id"]}` to `#{new_sidebar["id"]}`"
              @new_site.move_widget(old_widget, sidebar: new_sidebar)
            rescue WP::ClientError => e
              log_warn "Could not move widget: #{e.message}"
            end
          end
        end
      end

      log_info "Widget migration complete"
    end

    def old_sidebars
      @old_sidebars ||= @old_site.sidebars
    end

    def new_sidebars
      @new_sidebars ||= @new_site.sidebars
    end
  end
end
