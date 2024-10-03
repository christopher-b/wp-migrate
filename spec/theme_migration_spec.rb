require "spec_helper"

RSpec.describe WP::ThemeMigration do
  let(:old_site) { instance_double("WP::Site") }
  let(:new_site) { instance_double("WP::Site") }
  let(:migration) { described_class.new(old_site, new_site) }
  let(:original_theme) { "twentytwentyfour" }
  let(:default_theme) { described_class::DEFAULT_THEME }

  describe "#run" do
    before do
      allow(old_site).to receive(:theme).and_return(original_theme)
      allow(new_site).to receive(:theme_installed?).with(original_theme).and_return(true)
      allow(new_site).to receive(:activate_theme)
      allow(migration).to receive(:migrate_mods)
    end

    it "activates the original theme if installed" do
      allow(new_site).to receive(:theme).and_return("different_theme")
      expect(new_site).to receive(:activate_theme).with(original_theme)
      migration.run
    end

    it "activates the default theme if the original theme is not installed" do
      allow(new_site).to receive(:theme_installed?).with(original_theme).and_return(false)
      allow(new_site).to receive(:install_theme).and_raise(WP::CouldNotInstallThemeError)
      allow(new_site).to receive(:theme).and_return("new_theme")

      expect(new_site).to receive(:activate_theme).with(default_theme)
      migration.run
    end
  end

  describe "#install_original_theme" do
    before do
      allow(old_site).to receive(:theme).and_return(original_theme)
    end

    context "when the original theme installs successfully" do
      it "installs the original theme and logs the success" do
        allow(new_site).to receive(:install_theme).with(original_theme)
        expect(migration).to receive(:log_info).with("Theme installed: #{original_theme}")

        migration.install_original_theme
      end
    end

    context "when the original theme installation fails" do
      it "logs a warning if the installation fails" do
        allow(new_site).to receive(:install_theme).with(original_theme).and_raise(WP::CouldNotInstallThemeError.new("Installation failed"))
        expect(migration).to receive(:log_warn).with("Could not install theme #{original_theme}: Installation failed")

        migration.install_original_theme
      end
    end
  end

  describe "#theme_to_activate" do
    before do
      allow(old_site).to receive(:theme).and_return(original_theme)
    end

    context "when the original theme is installed" do
      it "returns the original theme" do
        allow(new_site).to receive(:theme_installed?).and_return(true)
        expect(migration.theme_to_activate).to eq(original_theme)
      end
    end

    context "when the original theme is not installed" do
      it "returns the default theme" do
        allow(new_site).to receive(:theme_installed?).and_return(false)
        expect(migration.theme_to_activate).to eq(default_theme)
      end
    end
  end

  describe "#migrate_mods" do
    let(:theme_mods) { { "header_color" => "#000", "background" => nil, "font_size" => "16px" } }

    before do
      allow(old_site).to receive(:theme_mods).and_return(theme_mods)
      allow(new_site).to receive(:set_theme_mod)
    end

    it "migrates valid theme mods" do
      expect(new_site).to receive(:set_theme_mod).with("header_color", "#000")
      expect(new_site).to receive(:set_theme_mod).with("font_size", "16px")

      migration.migrate_mods
    end

    it "skips theme mods with invalid values" do
      expect(new_site).not_to receive(:set_theme_mod).with("background", nil)
      migration.migrate_mods
    end
  end
end

