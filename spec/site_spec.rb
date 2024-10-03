require "spec_helper"

RSpec.describe WP::Site do
  let(:url) { "http://example.com/example-site" }
  let(:client) { instance_double("WP::Client") }
  let(:site_id) { 123 }
  let(:slug) { "example-site" }
  let(:title) { "Example Site" }
  let(:admin_email) { "admin@example.com" }
  let(:site) { described_class.new(url, client, site_id) }

  # before do
  #   allow(site).to receive(:log_info)
  # end

  describe "#menus" do
    it "loads menus from the client" do
      menu_list = [{"term_id" => 1, "slug" => "main-menu"}]
      menu_items = [{"id" => 1, "title" => "Home"}]

      allow(client).to receive(:menu_list).with(url).and_return(menu_list)
      allow(client).to receive(:menu_item_list).with(url, 1).and_return(menu_items)

      expect(site.menus).to eq([
        {"term_id" => 1, "slug" => "main-menu", "items" => menu_items}
      ])
    end
  end

  describe "#assign_menu" do
    let(:menu_slug) { "main-menu" }
    let(:location) { "primary" }

    it "assigns a menu to a location" do
      allow(client).to receive(:menu_location_assign).with(url, menu_slug, location)
      site.assign_menu(menu_slug, location)

      expect(client)
        .to have_received(:menu_location_assign)
        .with(url, menu_slug, location)
    end
  end

  describe "#install_theme" do
    let(:theme) { "new-theme" }

    it "installs a theme" do
      allow(client).to receive(:theme_install).with(theme)
      site.install_theme(theme)
      expect(client).to have_received(:theme_install).with(theme)
    end

    it "raises an error if theme installation fails" do
      allow(client).to receive(:theme_install).with(theme).and_raise(WP::ClientError)
      expect { site.install_theme(theme) }.to raise_error(WP::CouldNotInstallThemeError)
    end
  end

  describe "#activate_theme" do
    let(:theme) { "new-theme" }

    it "activates the theme" do
      allow(client).to receive(:theme_activate).with(url, theme).and_return(true)
      site.activate_theme(theme)
      expect(client).to have_received(:theme_activate).with(url, theme)
    end
  end

  describe "#move_widget" do
    let(:widget) { {"id" => 1, "name" => "Search"} }
    let(:sidebar) { {"id" => 1, "name" => "Primary Sidebar"} }

    it "moves the widget to the given sidebar" do
      allow(client).to receive(:widget_move).with(url, widget["id"], sidebar["id"], nil)
      site.move_widget(widget, sidebar: sidebar)
      expect(client).to have_received(:widget_move).with(url, widget["id"], sidebar["id"], nil)
    end
  end

  describe ".create" do
    it "creates a new site and deletes the first post" do
      allow(client).to receive(:site_create).with(slug, title, admin_email).and_return(site_id)
      allow(client).to receive(:site_url).with(site_id).and_return(url)
      allow(client).to receive(:post_delete).with(url, 1)

      new_site = described_class.create(slug, title, admin_email, client)
      expect(new_site.url).to eq(url)
      expect(client).to have_received(:post_delete).with(url, 1)
    end
  end

  describe ".get_by_slug" do
    it "retrieves a site by its slug" do
      site_list = [{"url" => url, "blog_id" => site_id}]
      allow(client).to receive(:site_list).and_return(site_list)

      found_site = described_class.get_by_slug(slug, client)
      expect(found_site.url).to eq(url)
      expect(found_site.id).to eq(site_id)
    end
  end
end
