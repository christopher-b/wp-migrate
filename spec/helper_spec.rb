require "rspec"

# Dummy class to include the Helper module for testing
class DummyClass
  include WP::Helper
end

RSpec.describe WP::Helper do
  let(:dummy) { DummyClass.new }

  describe "#copy_tempfile" do
    let(:path) { "tmp/test_file.txt" }
    let(:remote_path) { "#{Config.remote_file_dest}/#{path}" }
    let(:command) { "scp #{path} blog-new:~/#{remote_path}" }

    before do
      allow(dummy).to receive(:log_info)
      allow(dummy).to receive(:`).with(command).and_return("SCP completed")
    end

    # How do we test system commands? Need a different approach
    # it "executes the copy command" do
    #   dummy.copy_tempfile(path)
    #   expect(`#{command}`).to eq("SCP completed")
    # end
  end

  describe "#write_csv" do
    let(:csv_data) { "header1,header2\nvalue1,value2" }
    let(:filename) { "test.csv" }
    let(:tempfile_path) { "tmp/#{filename}" }

    before do
      allow(dummy).to receive(:tempfile).with(filename).and_return(tempfile_path)
      allow(File).to receive(:write).with(tempfile_path, csv_data)
    end

    it "creates a tempfile and writes CSV data to it" do
      dummy.write_csv(csv_data, filename)
      expect(File).to have_received(:write).with(tempfile_path, csv_data)
    end

    it "returns the correct path" do
      result = dummy.write_csv(csv_data, filename)
      expect(result).to eq(tempfile_path)
    end
  end

  describe "#tempfile" do
    let(:file) { "test.txt" }

    it "returns the correct tempfile path" do
      result = dummy.tempfile(file)
      expect(result).to eq(File.join("tmp", file))
    end
  end

  describe "logging methods" do
    let(:message) { "This is a log message." }

    it "logs info messages" do
      expect(WP.logger).to receive(:info)
      dummy.log_info(message)
    end

    it "logs debug messages" do
      expect(WP.logger).to receive(:debug)
      dummy.log_debug(message)
    end

    it "logs warn messages" do
      expect(WP.logger).to receive(:warn)
      dummy.log_warn(message)
    end

    it "logs error messages" do
      expect(WP.logger).to receive(:error)
      dummy.log_error(message)
    end
  end
end
