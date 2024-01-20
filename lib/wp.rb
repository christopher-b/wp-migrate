# frozen_string_literal: true

require "logger"
require "active_support/core_ext/hash"

require_relative "wp/helper"
require_relative "wp/cli"
require_relative "wp/client"
require_relative "wp/config"
require_relative "wp/errors"
require_relative "wp/migration"
require_relative "wp/site"
require_relative "wp/user_finder"
require_relative "wp/version"

require_relative "wp/content_migration"
require_relative "wp/file_migration"
require_relative "wp/theme_migration"
require_relative "wp/user_migration"
require_relative "wp/menu_migration"
require_relative "wp/widget_migration"

module WP
  class Error < StandardError; end

  def self.logger
    @logger ||= ::Logger.new($stdout, level: ENV.fetch("WP_LOG_LEVEL", Logger::INFO))
    # @logger ||= ::Logger.new($stdout).tap { |l| l.level = ENV.fetch("WP_LOG_LEVEL", Logger::DEBUG) }
  end
end
