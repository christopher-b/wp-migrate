module WP
  class ClientError < StandardError; end

  class CouldNotInstallThemeError < StandardError; end

  class SiteAlreadyExistsError < StandardError; end
end
