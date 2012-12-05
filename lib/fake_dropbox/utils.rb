require 'time'

module FakeDropbox
  module Utils
    def metadata(dropbox_path, list = false)
      full_path = File.join(@dropbox_dir, dropbox_path)
      bytes = File.directory?(full_path) ? 0 : File.size(full_path)

      metadata = {
        thumb_exists: false,
        bytes: bytes,
        modified: File.mtime(full_path).rfc822,
        path: File.join('/', dropbox_path),
        is_dir: File.directory?(full_path),
        size: "#{bytes} bytes",
        root: "dropbox"
      }

      if File.directory?(full_path)
        metadata[:icon] = "folder"
        if list
          entries = Dir.entries(full_path).reject { |x| ['.', '..'].include? x }
          metadata[:contents] = entries.map do |entry|
            metadata(File.join(dropbox_path, entry))
          end
        end
      else
        metadata[:icon] = case full_path
        when /\.(jpg|jpeg|gif|png)$/
          "page_white_picture"
        # todo: other file type to icon mappings
        else
          "page_white"
        end
        metadata[:rev] = begin
          @revs ||= {}
          @revs[full_path] ||= rand(1000000).to_s
        end
      end

      metadata
    end

    def safe_path(path)
      path.gsub(/(\.\.\/|\/\.\.)/, '')
    end

    def to_bool(value)
      return true if value == true || value =~ /(true|t|yes|y|1)$/i
      return false if value == false || value.nil? || value =~ /(false|f|no|n|0)$/i
      raise ArgumentError.new("Invalid value for Boolean: \"#{value}\"")
    end
  end
end
