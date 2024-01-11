require "open3"

# @TODO Break the commands out into mixins per category
# https://developer.wordpress.org/cli/commands/
module WP
  class Client
    def initialize(handle)
      @alias = handle
    end

    def export(url)
      content = exec("export", url: url, stdout: true) # , skip_comments: true)
      filename_url = url.gsub(/[\/:]/, "-")
      filename = "export-#{filename_url}.xml"
      File.write(filename, content)
      filename
    end

    def import(url, export_file, user_map_file)
      exec("import #{export_file}", url: url, authors: user_map_file)
    end

    def menu_item_list(url, menu)
      JSON.parse(exec("menu item list #{menu}", url: url, format: "json"))
    end

    def menu_list(url)
      JSON.parse(exec("menu list", url: url, format: "json"))
    end

    def menu_location_assign(url, menu, location)
      exec("menu location assign #{menu} #{location}", url: url)
    end

    def option_get(url, option_name)
      exec("option get #{option_name}", url: url)
    end

    def plugin_activate(url, plugin)
      exec("plugin activate #{plugin}", url: url)
    end

    def plugin_is_active(url, plugin)
      exec("plugin is-active #{plugin}", url: url)
      @last_status.zero?
    end

    def post_delete(url, id)
      exec("post delete #{id}", url: url)
    end

    def site_create(slug, title, admin_email)
      args = {
        slug: slug,
        title: title,
        email: admin_email,
        porcelain: true
      }
      exec("site create", args)
    end

    def site_id(url)
      url = url.sub "http://", "https://"
      @site_list_for_id ||= site_list(fields: "blog_id,url")

      site = @site_list_for_id
        .each { _1["url"].sub! "http://", "https://" }
        .find { _1["url"].include? url }

      unless site
        message = "Couldn't extract ID from list: URL #{url} in #{@site_list_for_id}"
        raise message
      end

      site["blog_id"]
    end

    def site_list(args = {})
      defaults = {format: "json"}
      json = exec("site list", args.merge(defaults))
      JSON.parse(json)
    end

    def site_url(site_id)
      site_list(field: "url", site__in: site_id).first
    end

    def theme_activate(url, theme)
      exec("theme activate #{theme}", url: url)
    end

    def theme_current(url)
      theme_list(url, status: "active", field: "name")
    end

    def theme_details(theme)
      JSON.parse(exec("theme get #{theme}", format: "json"))
    end

    def theme_install(theme)
      exec("theme install #{theme}")
    end

    def theme_is_installed(theme)
      exec("theme is-installed #{theme}")
      @last_status.zero?
    end

    def theme_list(url, args = {})
      defaults = {url: url}
      exec("theme list", args.merge(defaults))
    end

    def theme_search(term)
      JSON.parse(exec("theme search #{term}", format: "json"))
    end

    def user_import(url, file)
      exec("user import-csv #{file}", url: url)
    end

    def user_list(url)
      json = exec("user list", url: url, format: "json", fields: "display_name,user_email,roles,user_login,first_name,last_name")
      JSON.parse(json)
    end

    private

    def exec(wp_command, args = {})
      default_args = {"skip-plugins": "sitewide-privacy-options"}
      all_args = args.merge(default_args)

      command = "bin/wp-cli.phar #{@alias} #{wp_command} #{parse_args(all_args)}"

      output, error, status = Open3.capture3(command)
      @last_status = status.exitstatus
      raise WP::ClientError, error.chomp if !error.empty? && !error.match?(/^PHP Notice/)
      output.chomp
      # rescue StandardError => e
      #   pp e.inspect
      #   pp e.message
      #   pp error
      #   pp status
      #   raise e
    end

    def parse_args(args)
      args.collect { |k, v| v.is_a?(String) ? "--#{k}='#{v}'" : "--#{k}" }.join(" ")
    end

    def log(msg, level = Logger::DEBUG)
      logger.add(level, msg)
    end

    def logger
      @logger ||= Logger.new($stdout).tap do |logger|
        log_level = ENV.fetch("LOG_LEVEL", "INFO")
        logger.level = Logger.const_get(log_level)
      end
    end
  end
end
