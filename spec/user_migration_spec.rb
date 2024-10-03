require "spec_helper"
require "csv"

RSpec.describe WP::UserMigration do
  let(:old_site) { instance_double(WP::Site, url: "http://oldsite.com", users: old_users) }
  let(:new_site) { instance_double(WP::Site, url: "http://newsite.com") }
  let(:ldap_users) do
    {
      "john_doe" => {samaccountname: "john_doe", ocaderpid: "12345", displayname: "John Doe", givenname: "John", sn: "Doe"}
    }
  end
  let(:old_users) do
    [
      {"user_login" => "john_doe", "user_email" => "john@example.com", "roles" => "editor"}
    ]
  end
  let(:migration) { WP::UserMigration.new(old_site, new_site) }

  before do
    allow(WP::UserFinder).to receive(:get_users_for_logins).and_return(ldap_users)
    allow(new_site).to receive(:import_users).and_return("Import completed")
  end

  describe "#corrected_old_users" do
    it "replaces user logins with LDAP-based SIS IDs or usernames" do
      corrected_users = migration.send(:corrected_old_users)

      expect(corrected_users).to contain_exactly(
        {
          user_email: "john@example.com",
          roles: "editor",
          display_name: "John Doe",
          user_login: "12345",  # This comes from LDAP
          first_name: "John",
          last_name: "Doe"
        }
      )
    end
  end

  describe "#export_csv" do
    it "exports corrected users to CSV" do
      subject = WP::UserMigration.new(old_site, new_site)
      csv_content = subject.send(:export_csv)

      expect(csv_content).to include("user_email,roles,display_name,user_login,first_name,last_name")
      expect(csv_content).to include("john@example.com,editor,John Doe,12345,John,Doe")
    end
  end

  describe "#login_map" do
    it "generates the login map based on LDAP users" do
      subject = WP::UserMigration.new(old_site, new_site)
      map = subject.send(:login_map)

      expect(map).to include(["john_doe", "12345"])
    end
  end

  describe "#import" do
    it "logs and imports the user CSV to the new site" do
      subject = WP::UserMigration.new(old_site, new_site)
      expect(new_site).to receive(:import_users).with(anything).and_return("Import completed")
      subject.import
    end
  end
end
