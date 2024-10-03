require "rspec"

RSpec.describe WP::ContentMigration do
  let(:old_site) { instance_double("OldSite", export_content: "export_data", is_plugin_active?: true) }
  let(:new_site) { instance_double("NewSite", enable_plugin: nil, import_content: "import_result") }
  let(:login_map) { "path/to/mapping.csv" }
  let(:migration) { WP::ContentMigration.new(old_site, new_site, login_map) }

  describe "#initialize" do
    it "initializes with old, new site, and login map" do
      expect(migration.instance_variable_get(:@old_site)).to eq(old_site)
      expect(migration.instance_variable_get(:@new_site)).to eq(new_site)
      expect(migration.login_map_csv).to eq(login_map)
    end
  end

  describe "#run" do
    before do
      allow(migration).to receive(:log_info)
      allow(migration).to receive(:copy_tempfile).and_return("remote_export_path")
      allow(migration).to receive(:copy_login_map).and_return("remote_login_map_path")
      allow(migration).to receive(:import).and_return("import_result")
    end

    context "when the importer plugin is not active" do
      before do
        allow(migration).to receive(:log_info)
        allow(new_site).to receive(:is_plugin_active?).with("wordpress-importer").and_return(false)
        allow(new_site).to receive(:enable_plugin)
      end

      it "calls enable_plugin on new_site" do
        migration.run
        expect(new_site).to have_received(:enable_plugin).with("wordpress-importer")
      end
    end

    context "when the importer plugin is already active" do
      before do
        allow(migration).to receive(:log_info)
        allow(new_site).to receive(:is_plugin_active?).with("wordpress-importer").and_return(true)
      end

      it "does not call enable_plugin on new_site" do
        migration.run
        expect(new_site).not_to have_received(:enable_plugin)
      end
    end
  end
end
