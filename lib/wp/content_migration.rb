module WP
  class ContentMigration
    include Helper

    LOGIN_MAP_FILENAME = "mapping.csv"

    attr_accessor :login_map_csv

    def initialize(old, new, login_map = nil)
      @old_site = old
      @new_site = new
      @login_map_csv = login_map
    end

    def run
      log_info "Migrating content"

      enable_importer_plugin

      remote_export_path = copy_tempfile(export)
      remote_login_map_path = copy_login_map
      import_result = import(remote_export_path, remote_login_map_path)

      log_info "Import result: #{import_result}"
      log_info "Content migration complete"
    end

    private

    def enable_importer_plugin
      importer = "wordpress-importer"
      if @new_site.is_plugin_active?(importer)
        log_info "Importer plugin already enabled"
      else
        @new_site.enable_plugin(importer)
      end
    end

    def export
      @export ||= @old_site.export_content
    end

    def import(remote_export_path, remote_login_map_path)
      @new_site.import_content(remote_export_path, remote_login_map_path)
    end

    def copy_login_map
      copy_csv_to_remote(@login_map_csv, LOGIN_MAP_FILENAME)
    end
  end
end
