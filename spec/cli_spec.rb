require "thor"
require "wp"
require_relative "../lib/wp/cli"

RSpec.describe WP::CLI do
  describe ".exit_on_failure?" do
    it "returns true" do
      expect(WP::CLI.exit_on_failure?).to be true
    end
  end

  describe "#migrate" do
    let(:slug) { "example-slug" }
    let(:admin_email) { "admin@example.com" }
    let(:old_url) { "http://blog.ocad.ca/wordpress/#{slug}" }
    let(:migration_double) { instance_double(WP::Migration) }

    before do
      allow(WP::Migration).to receive(:new).with(old_url, slug, admin_email).and_return(migration_double)
      allow(migration_double).to receive(:start)
    end

    it "creates a new WP::Migration with the correct arguments" do
      subject.migrate(slug, admin_email)
      expect(WP::Migration).to have_received(:new).with(old_url, slug, admin_email)
    end

    it "calls start on the WP::Migration instance" do
      subject.migrate(slug, admin_email)
      expect(migration_double).to have_received(:start)
    end
  end
end
