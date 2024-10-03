require "spec_helper"

RSpec.describe WP::WidgetMigration do
  let(:old_site) { instance_double(WP::Site, theme: "old_theme", sidebars: old_sidebars) }
  let(:new_site) { instance_double(WP::Site, theme: "old_theme", sidebars: new_sidebars) }
  let(:inactive_sidebar) { {"id" => "wp_inactive_widgets", "name" => "Inactive Widgets"} }

  let(:old_sidebars) do
    [
      {"id" => "sidebar-1", "name" => "Main Sidebar"},
      {"id" => "footer-1", "name" => "Footer"}
    ]
  end

  let(:new_sidebars) do
    [
      {"id" => "sidebar-1", "name" => "Main Sidebar"},
      {"id" => "footer-1", "name" => "Footer"},
      inactive_sidebar
    ]
  end

  let(:old_widgets) do
    [
      {"id" => "widget-1", "name" => "Old Widget 1"},
      {"id" => "widget-2", "name" => "Old Widget 2"}
    ]
  end

  let(:new_widgets) do
    [
      {"id" => "widget-2", "name" => "Old Widget 2"},
      {"id" => "widget-3", "name" => "New Widget 3"}
    ]
  end

  before do
    allow(old_site).to receive(:widgets).with(anything).and_return(old_widgets)
    allow(new_site).to receive(:widgets).with(anything).and_return(new_widgets)
    allow(new_site).to receive(:move_widget)
  end

  describe "#run" do
    context "when themes are not the same" do
      let(:new_site) { instance_double(WP::Site, theme: "different_theme", sidebars: new_sidebars) }

      it "logs a message and skips the migration" do
        expect_any_instance_of(WP::WidgetMigration).to receive(:log_info).with("Migrating widgets")
        expect_any_instance_of(WP::WidgetMigration).to receive(:log_info).with("Theme not synced, skipping")

        subject = WP::WidgetMigration.new(old_site, new_site)
        subject.run
      end
    end

    context "when themes are the same" do
      it "moves widgets that are not present in old_sidebar to inactive widgets" do
        expect(new_site).to receive(:move_widget).with(new_widgets[1], sidebar: inactive_sidebar)

        subject = WP::WidgetMigration.new(old_site, new_site)
        subject.run
      end

      it "adds widgets not present in new_sidebar" do
        expect(new_site).to receive(:move_widget).with(old_widgets[0], sidebar: new_sidebars[0])

        subject = WP::WidgetMigration.new(old_site, new_site)
        subject.run
      end
    end
  end

  describe "#old_sidebars" do
    it "returns the old site sidebars" do
      subject = WP::WidgetMigration.new(old_site, new_site)
      expect(subject.old_sidebars).to eq(old_sidebars)
    end
  end

  describe "#new_sidebars" do
    it "returns the new site sidebars" do
      subject = WP::WidgetMigration.new(old_site, new_site)
      expect(subject.new_sidebars).to eq(new_sidebars)
    end
  end
end

