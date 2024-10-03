require "rspec"

# Dummy classes to simulate old and new sites
class OldSite
  def menus
    [
      {"slug" => "main-menu", "locations" => ["header"]},
      {"slug" => "footer-menu", "locations" => ["footer"]}
    ]
  end
end

class NewSite
  def assign_menu(slug, location)
    # Simulate the assignment of a menu
  end

  def menus
    # Return a simulated list of new menus
    [{"slug" => "main-menu"}, {"slug" => "footer-menu"}]
  end
end

RSpec.describe WP::MenuMigration do
  let(:old_site) { OldSite.new }
  let(:new_site) { NewSite.new }
  let(:menu_migration) { WP::MenuMigration.new(old_site, new_site) }

  describe "#run" do
    before do
      allow(menu_migration).to receive(:log_info)
      allow(menu_migration).to receive(:matching_new_menu).and_call_original
    end

    it "assigns old menus to their matching new locations" do
      expect(new_site).to receive(:assign_menu).with("main-menu", "header")
      expect(new_site).to receive(:assign_menu).with("footer-menu", "footer")

      menu_migration.run
    end
  end

  describe "#matching_new_menu" do
    let(:menu) { {"slug" => "main-menu"} }

    it "finds the matching new menu by slug" do
      expect(menu_migration.matching_new_menu(menu))
        .to eq(new_site.menus[0])
    end

    it "returns nil if no matching menu is found" do
      expect(menu_migration.matching_new_menu({"slug" => "non-existent-menu"})).to be_nil
    end
  end
end
