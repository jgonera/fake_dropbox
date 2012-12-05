require 'time'

module FakeDropbox

  # todo:
  # * extract dropbox_root into a proper "Dropbox Filesystem" object
  # * don't use class vars
  # * handle deletions
  #
  class Entry
    # directory on disk containing our fake dropbox
    attr_reader :dropbox_root

    # path relative to dropbox root
    attr_reader :dropbox_path

    def initialize(dropbox_root, dropbox_path)
      @dropbox_root = dropbox_root
      @dropbox_path = dropbox_path
    end

    def full_path
      File.join(dropbox_root, dropbox_path)
    end

    def directory?
      File.directory?(full_path)
    end

    def metadata(list_contents = false)
      hash = get_metadata.dup
      if directory? and list_contents
        children = Dir.entries(full_path).reject { |x| ['.', '..'].include? x }
        hash[:contents] = children.map do |child_path|
          Entry.new(dropbox_root, child_path).metadata
        end
      end
      hash
    end

    def get_metadata
      metadatas[full_path] ||= build_metadata
    end

    def update_metadata
      metadatas[full_path] = build_metadata
    end

    def metadatas
      # todo: don't use class vars -- we need it because Sinatra loses instance data between requests
      @@metadatas ||= {}
    end

    def build_metadata
      bytes = directory? ? 0 : File.size(full_path)

      metadata = {
        thumb_exists: false,
        bytes: bytes,
        modified: File.mtime(full_path).rfc822,
        path: File.join('/', dropbox_path),
        is_dir: directory?,
        size: "#{bytes} bytes",
        root: "dropbox"
      }

      if directory?
        metadata[:icon] = "folder"
      else
        metadata[:icon] = case full_path
        when /\.(jpg|jpeg|gif|png)$/
          "page_white_picture"
        # todo: other file type to icon mappings
        else
          "page_white"
        end
        metadata[:rev] = rand(100000000).to_s(16)
      end

      metadata
    end
  end
end
