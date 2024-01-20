module WP
  class FileMigration
    include Helper

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating files"
      copy_archive_to_wp
      log_info "File migration complete"
    end

    def copy_archive_to_wp
      # We rsync remaining files, in case WP missed anything
      src = "~/blogs.ocaduwebspace.ca/migration-files/uploads/#{@old_site.id}/files/*"
      dst = "~/blogs.ocaduwebspace.ca/www/wp-content/uploads/sites/#{@new_site.id}"
      command = "ssh blog-new 'rsync -a #{src} #{dst}'"

      log_info "Syncing archive to live site: #{command}"
      `#{command}`
    end
  end
end
