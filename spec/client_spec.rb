require "open3"
require "json"
require_relative "../lib/wp/client"

RSpec.describe WP::Client do
  let(:client) { WP::Client.new("my_alias") }
  let(:url) { "http://example.com" }

  describe "#export" do
    let(:content) { "<xml>content</xml>" }
    let(:filename) { "export-http---example.com.xml" }

    before do
      allow(client)
        .to receive(:exec)
        .with("export", url: url, stdout: true)
        .and_return(content)
      allow(File).to receive(:write)
    end

    it "writes the exported content to a file" do
      client.export(url)
      expect(File).to have_received(:write).with(filename, content)
    end

    it "returns the filename" do
      expect(client.export(url)).to eq(filename)
    end
  end

  describe "#menu_item_list" do
    let(:menu) { "main-menu" }
    let(:json_response) { '[{"id":1,"name":"Home"}]' }

    before do
      allow(client)
        .to receive(:exec)
        .with("menu item list #{menu}", url: url, format: "json")
        .and_return(json_response)
    end

    it "parses the JSON response" do
      result = client.menu_item_list(url, menu)
      expect(result).to eq([{"id" => 1, "name" => "Home"}])
    end
  end

  describe "#menu_list" do
    let(:json_response) { '[{"term_id":1,"name":"Main Menu"},{"term_id":2,"name":"Footer Menu"}]' }

    before do
      allow(client)
        .to receive(:exec)
        .with("menu list", url: url, format: "json")
        .and_return(json_response)
    end

    it "parses the JSON response" do
      result = client.menu_list(url)
      expect(result)
        .to eq([
          {"term_id" => 1, "name" => "Main Menu"},
          {"term_id" => 2, "name" => "Footer Menu"}
        ])
    end
  end

  describe "#plugin_is_active" do
    let(:plugin) { "akismet" }

    before do
      allow(client)
        .to receive(:exec)
        .with("plugin is-active #{plugin}", url: url)
        .and_return("")
    end

    it "returns true when the last status is zero" do
      client.instance_variable_set(:@last_status, 0)
      expect(client.plugin_is_active(url, plugin)).to be true
    end

    it "returns false when the last status is non-zero" do
      client.instance_variable_set(:@last_status, 1)
      expect(client.plugin_is_active(url, plugin)).to be false
    end
  end

  describe "#theme_mod_list" do
    let(:json_response) { '[{"key":"background_color","value":"#ffffff"}]' }

    before do
      allow(client)
        .to receive(:exec)
        .with("theme mod list", url: url, format: "json")
        .and_return(json_response)
    end

    it "parses the theme mods JSON response into a hash" do
      result = client.theme_mod_list(url)
      expect(result).to eq({"background_color" => "#ffffff"})
    end
  end

  describe "#site_id" do
    let(:site_list) do
      [
        {"blog_id" => 1, "url" => "https://example.com"},
        {"blog_id" => 2, "url" => "https://another-example.com"}
      ]
    end

    before do
      allow(client)
        .to receive(:site_list)
        .with(fields: "blog_id,url")
        .and_return(site_list)
    end

    it "returns the correct site ID for the given URL" do
      expect(client.site_id("https://example.com")).to eq(1)
    end

    it "raises an error when the URL is not found in the site list" do
      expect {
        client.site_id("https://not-found.com")
      }.to raise_error(RuntimeError, /Couldn't extract ID/)
    end
  end

  describe "#site_list" do
    it "uses default arguments when none are provided" do
      allow(client)
        .to receive(:exec)
        .with("site list", {format: "json"})
        .and_return("{}")

      client.site_list
      expect(client).to have_received(:exec).with("site list", format: "json")
    end

    it "uses allows a custom format" do
      allow(client)
        .to receive(:exec)
        .with("site list", {format: "test"})
        .and_return("{}")

      client.site_list(format: "test")
      expect(client).to have_received(:exec).with("site list", format: "test")
    end
  end

  describe "#widget_move" do
    let(:widget_id) { "widget-1" }
    let(:sidebar_id) { "sidebar-1" }
    let(:position) { 1 }
    let(:params_with_position) {
      {"url" => url, "position" => position, "sidebar-id" => sidebar_id}
    }
    let(:params_without_position) {
      {"url" => url, "sidebar-id" => sidebar_id}
    }
    let(:params_without_sidebar_and_position) {
      {"url" => url}
    }

    before do
      allow(client).to receive(:exec)
    end

    context "when both sidebar_id and position are provided" do
      it "executes the widget move command with position and sidebar_id" do
        client.widget_move(url, widget_id, sidebar_id, position)
        expect(client)
          .to have_received(:exec)
          .with("widget move #{widget_id}", params_with_position)
      end
    end

    context "when position is nil" do
      let(:position) { nil }

      it "executes the widget move command with only sidebar_id" do
        client.widget_move(url, widget_id, sidebar_id, position)
        expect(client)
          .to have_received(:exec)
          .with("widget move #{widget_id}", params_without_position)
      end
    end

    context "when both position and sidebar_id are nil" do
      let(:sidebar_id) { nil }
      let(:position) { nil }

      it "executes the widget move command without position and sidebar_id" do
        client.widget_move(url, widget_id, sidebar_id, position)
        expect(client)
          .to have_received(:exec)
          .with("widget move #{widget_id}", params_without_sidebar_and_position)
      end
    end
  end

  describe "#parse_args" do
    it "correctly parses string arguments" do
      args = {
        "url" => "http://example.com",
        "format" => "json"
      }
      result = client.parse_args(args)
      expect(result).to eq("--url='http://example.com' --format='json'")
    end

    it "correctly parses boolean arguments" do
      args = {
        "url" => "http://example.com",
        "skip-plugins" => true
      }
      result = client.parse_args(args)
      expect(result).to eq("--url='http://example.com' --skip-plugins")
    end

    it "handles empty arguments" do
      args = {}
      result = client.parse_args(args)
      expect(result).to eq("")
    end

    it "handles a mix of string and boolean arguments" do
      args = {
        "url" => "http://example.com",
        "format" => "json",
        "skip-plugins" => true
      }
      result = client.parse_args(args)
      expect(result).to eq("--url='http://example.com' --format='json' --skip-plugins")
    end
  end
end
