# WP Migrate
A tool to migrate WP sites between WP Multisite instances

## Installation

 - Download wp-cli (https://wp-cli.org/) and place wp-cli.phar in ./bin
 - `bundle install`
 - `cp lib/wp/config-example.rb lib/wp/config.rb`
 - `cp wp-cli.local.yml.example wp-cli.local.yml`
 - Edit lib/wp/config.rb and wp-cli.local.yml.example

## Usage

This tool assumes you have wp-cli aliases defined and accessible to wp-cli (for example, in wp-cli.local.yml). It will use aliases named @wpmu-old and @wpmu-new.
It also assumes you have ssh access to both servers.

`bundle exec exe/wp-migrate migrate [old site slug] [new admin email address]`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

