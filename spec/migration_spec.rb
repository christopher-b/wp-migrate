require "spec_helper"

RSpec.describe WP::Migration do
  let(:old_url) { "http://example-old.com" }
  let(:new_site_slug) { "new-site" }
  let(:admin_email) { "admin@example.com" }
  let(:old_site) { instance_double("WP::Site") }
  let(:new_site) { instance_double("WP::Site") }
  let(:user_migration) { instance_double("WP::UserMigration") }
  let(:content_migration) { instance_double("WP::ContentMigration") }
  let(:file_migration) { instance_double("WP::FileMigration") }
  let(:theme_migration) { instance_double("WP::ThemeMigration") }
  let(:menu_migration) { instance_double("WP::MenuMigration") }
  let(:widget_migration) { instance_double("WP::WidgetMigration") }

  subject { described_class.new(old_url, new_site_slug, admin_email) }

  before do
    allow(old_site).to receive(:name).and_return("Test")
    allow(new_site).to receive(:url).and_return("https://example-new.com")
    allow(WP::Site).to receive(:new).with(old_url, anything).and_return(old_site)
    allow(WP::Site).to receive(:create).with(new_site_slug, anything, admin_email, anything).and_return(new_site)
    allow(subject).to receive(:user_migration).and_return(user_migration)
    allow(subject).to receive(:content_migration).and_return(content_migration)
    allow(subject).to receive(:file_migration).and_return(file_migration)
    allow(subject).to receive(:theme_migration).and_return(theme_migration)
    allow(subject).to receive(:menu_migration).and_return(menu_migration)
    allow(subject).to receive(:widget_migration).and_return(widget_migration)
    allow(subject).to receive(:log_info)
    allow(user_migration).to receive(:run)
    allow(content_migration).to receive(:run)
    allow(file_migration).to receive(:run)
    allow(theme_migration).to receive(:run)
    allow(menu_migration).to receive(:run)
    allow(widget_migration).to receive(:run)
  end

  describe "#start" do
    it "runs all migration processes" do

      subject.start

      expect(user_migration).to have_received(:run)
      expect(content_migration).to have_received(:run)
      expect(file_migration).to have_received(:run)
      expect(theme_migration).to have_received(:run)
      expect(menu_migration).to have_received(:run)
      expect(widget_migration).to have_received(:run)
    end

    it "creates a new site" do
      expect(WP::Site).to receive(:create).with(new_site_slug, anything, admin_email, anything)
      subject.start
    end

    context "when the site already exists" do
      before do
        allow(WP::Site).to receive(:create).and_raise(WP::SiteAlreadyExistsError)
        allow(WP::Site).to receive(:get_by_slug).with(new_site_slug, anything).and_return(new_site)
      end

      it "retrieves the existing site" do
        expect(WP::Site).to receive(:get_by_slug).with(new_site_slug, anything)
        subject.start
      end
    end
  end

  describe "#old_site" do
    it "returns the old site" do
      expect(subject.old_site).to eq(old_site)
    end
  end

  describe "#new_site" do
    it "returns the new site" do
      expect(subject.new_site).to eq(new_site)
    end
  end
end

