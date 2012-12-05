require 'spec_helper'

describe 'FakeDropbox::Entry' do
  def build_entry path
    FakeDropbox::Entry.new(fixture_path, path)
  end

  describe "#metadata" do
    it "returns correct metadata" do
      metadata = build_entry('/').metadata
      metadata.should include :thumb_exists, :bytes, :modified, :path,
        :is_dir, :size, :root, :icon
    end

    context "when path is a file" do
      it "returns file metadata" do
        file_path = fixture_path('dummy.txt')
        metadata = build_entry('dummy.txt').metadata
        metadata.should_not include :contents
        metadata.should include :rev
        metadata[:is_dir].should == false
        metadata[:bytes].should == File.size(file_path)
        metadata[:path].should == '/dummy.txt'
        metadata[:modified].should == File.mtime(file_path).rfc822
        metadata[:icon].should == "page_white"
      end

      context 'when file has not changed' do
        it 'returns the same rev' do
          rev1 = build_entry('dummy.txt').metadata[:rev]
          rev2 = build_entry('dummy.txt').metadata[:rev]
          rev1.should == rev2
          rev1.should_not be_nil
          rev2.should_not be_nil
        end
      end

      context 'when file has changed (via update_metadata)' do
        it 'returns a new rev' do
          rev1 = build_entry('dummy.txt').metadata[:rev]
          build_entry('dummy.txt').update_metadata
          rev2 = build_entry('dummy.txt').metadata[:rev]
          rev1.should_not == rev2
          rev1.should_not be_nil
          rev2.should_not be_nil
        end
      end
    end

    context "when path is an image" do
      it "returns image metadata" do
        file_path = fixture_path("dropbox.png")
        metadata = build_entry('dropbox.png').metadata
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
        metadata = build_entry('/').metadata
        metadata[:is_dir].should == true
        metadata[:bytes].should == 0
        metadata[:path].should == '/'
        metadata[:modified].should == File.mtime(fixture_path).rfc822
        metadata[:icon].should == "folder"
      end

      context "when list is true" do
        before :each do
          @tmpdir = Dir.mktmpdir 'fake_dropbox-test'
        end

        after :each do
          FileUtils.remove_entry_secure @tmpdir
        end

        it "returns the metadata of all its children too" do
          Dir.mkdir(File.join(@tmpdir, 'stuff'))
          FileUtils.cp(fixture_path('dummy.txt'), File.join(@tmpdir, 'stuff'))
          FileUtils.cp(fixture_path('dropbox.png'), File.join(@tmpdir, 'stuff'))

          metadata = FakeDropbox::Entry.new(@tmpdir, '/stuff').metadata(true)
          metadata.should include :contents
          metadata[:contents].should include(FakeDropbox::Entry.new(@tmpdir, '/stuff/dummy.txt').metadata)
          metadata[:contents].should include(FakeDropbox::Entry.new(@tmpdir, '/stuff/dropbox.png').metadata)
        end
      end
    end

  end
end
