require 'spec_helper'

class DummyClass
  include FakeDropbox::Utils

  def initialize(dropbox_dir)
    @dropbox_dir = dropbox_dir
  end
end

describe 'FakeDropbox::Utils' do
  subject { DummyClass.new(fixture_path) }

  describe "#metadata" do
    it "returns correct metadata" do
      metadata = subject.metadata('/')
      metadata.should include :thumb_exists, :bytes, :modified, :path,
        :is_dir, :size, :root, :icon
    end

    context "when path is a file" do
      it "returns file metadata" do
        file_path = fixture_path('dummy.txt')
        metadata = subject.metadata('dummy.txt')
        metadata.should_not include :contents
        metadata.should include :rev
        metadata[:is_dir].should == false
        metadata[:bytes].should == File.size(file_path)
        metadata[:path].should == '/dummy.txt'
        metadata[:modified].should == File.mtime(file_path).rfc822
        metadata[:icon].should == "page_white"
      end
    end

    context "when path is an image" do
      it "returns image metadata" do
        file_path = fixture_path("dropbox.png")
        metadata = subject.metadata('dropbox.png')
        metadata.should_not include :contents
        metadata.should include :rev
        metadata[:is_dir].should == false
        metadata[:bytes].should == File.size(file_path)
        metadata[:path].should == '/dropbox.png'
        metadata[:modified].should == File.mtime(file_path).rfc822
        metadata[:icon].should == "page_white_picture"
      end
    end

    context "when path is a dir" do
      it "returns dir metadata" do
        metadata = subject.metadata('/')
        metadata[:is_dir].should == true
        metadata[:bytes].should == 0
        metadata[:path].should == '/'
        metadata[:modified].should == File.mtime(fixture_path).rfc822
        metadata[:icon].should == "folder"
      end

      context "when list is true" do
        it "returns the metadata of all its children too" do
          metadata = subject.metadata('/', true)
          metadata.should include :contents
          metadata[:contents].should include(subject.metadata('dummy.txt'))
          metadata[:contents].should include(subject.metadata('dropbox.png'))
        end
      end
    end
  end

  describe "#safe_path" do
    it "returns a safe path" do
      subject.safe_path('../aa/../bb/..').should == 'aa/bb'
    end
  end
end
