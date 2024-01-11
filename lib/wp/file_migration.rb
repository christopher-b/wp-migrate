module WP
  class FileMigration
    include Helper

    def initialize(old, new)
      @old_site = old
      @new_site = new
    end

    def run
      log_info "Migrating files"

      # ask_text = <<~EOF
      #   Here is the manual part:
      #   ssh blog-legacy
      #   sudo su
      #   cp -r /mnt/nfs_blog/blog.ocad.ca/htdocs/wordpress/wp-content/blogs.dir/#{@old_site.id} ./migrate-files

      #   Press enter when complete
      # EOF
      # # _wait = ask(ask_text)
      # puts ask_text
      # _wait = $stdin.gets

      # source = "~/migrate-files/#{@old_site.id}/*"
      # target = "~/blogs.ocaduwebspace.ca/www/wp-content/uploads/sites/#{@new_site.id}"
      # command = "scp -r blog-legacy:#{source} blog-new:#{target}"
      # log_info "Starting file copy, this could take a while: `#{command}`"
      # `#{command}`

      copy_files_to_wp

      log_info "File migration complete"
    end

    def copy_files_to_wp
      src = "~/blogs.ocaduwebspace.ca/migration-files/uploads/#{@old_site.id}/*"
      dst = "~/blogs.ocaduwebspace.ca/www/wp-content/uploads/sites/#{@new_site.id}"
      command = "rsync -a #{src} #{dst}"

      log_info "Syncing archive to live site: #{command}"
      `#{command}`
    end
  end
end
