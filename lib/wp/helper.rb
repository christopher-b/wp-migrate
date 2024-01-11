module WP
  module Helper
    def self.included base
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
      def copy_csv_to_remote(csv, filename)
        log_info "Sending CSV #{filename} to remote"

        path = write_csv(csv, filename)
        copy_tempfile(path)
      end

      def copy_tempfile(path)
        (Config.remote_file_dest + "/#{path}").tap do |remote_path|
          command = "scp #{path} blog-new:~/#{remote_path}"

          log_info "Copying tempfile file to remote: `#{command}`"

          `#{command}`
        end
      end

      def write_csv(csv, file_name)
        tempfile(file_name).tap do |path|
          File.write(path, csv)
        end
      end

      def tempfile(file)
        File.join("tmp", file)
      end

      def log_info(msg)
        WP.logger.info { msg }
      end

      def log_debug(msg)
        WP.logger.debug { msg }
      end

      def log_warn(msg)
        WP.logger.warn { msg }
      end

      def log_error(msg)
        WP.logger.error { msg }
      end
    end

    module ClassMethods
      def log_info(msg)
        WP.logger.info { msg }
      end

      def log_debug(msg)
        WP.logger.debug { msg }
      end

      def log_warn(msg)
        WP.logger.warn { msg }
      end

      def log_error(msg)
        WP.logger.error { msg }
      end
    end
  end
end
