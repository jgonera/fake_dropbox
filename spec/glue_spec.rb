require 'spec_helper'

describe "FakeDropbox::Glue" do
  before do
    Dir.stub(:tmpdir).and_return('/tmp')
    File.stub(:exists?).and_return(true)
  end
    
  describe ".new" do
    it "stubs the request with WebMock" do
      stub_request = double('stub_request')
      WebMock.should_receive(:stub_request).and_return(stub_request)
      stub_request.should_receive(:to_return)
      FakeDropbox::Glue.new('/tmp/somethingnonexistant')
    end
    
    context "when invoked with an argument" do
      it "sets the dropbox_dir" do
        glue = FakeDropbox::Glue.new('/tmp/somethingnonexistant')
        glue.dropbox_dir.should == '/tmp/somethingnonexistant'
      end
    end
    
    context "when invoked with no arguments" do
      it "creates dropbox_dir in system temp path" do
        glue = FakeDropbox::Glue.new
        glue.dropbox_dir.should == '/tmp/fake_dropbox'
      end
    end
  end
  
  describe "#empty!" do
    context "when dropbox_dir is in temp path" do
      subject { FakeDropbox::Glue.new('/tmp/somethingnonexistant') }
      
      it "deletes the dropbox_dir and all its contents" do
        Dir.should_receive(:glob).with('/tmp/somethingnonexistant/*').and_return(['sth'])
        FileUtils.should_receive(:remove_entry_secure).with('sth')
        subject.empty!
      end
    end
    
    shared_examples_for "dangerous" do
      it "does not delete the dropbox_dir" do
        FileUtils.should_not_receive(:remove_entry_secure)
        begin
          subject.empty!
        rescue
        end
      end

      it "raises an exception" do
        lambda { subject.empty! }.should raise_error
      end
    end
    
    context "when dropbox_dir is not in temp path" do
      subject { FakeDropbox::Glue.new('/sth') }
      it_behaves_like "dangerous"
    end
    
    context "when dropbox_dir is not in temp path and is not absolute" do
      subject { FakeDropbox::Glue.new('/tmp/../somethingnonexistant') }
      it_behaves_like "dangerous"
    end
  end
end
