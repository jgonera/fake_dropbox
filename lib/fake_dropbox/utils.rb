require 'time'

module FakeDropbox
  module Utils
    def metadata(dropbox_path, list = false)
      path = File.join(@dropbox_dir, dropbox_path)
      bytes = File.directory?(path) ? 0 : File.size(path)
      
      metadata = {
        thumb_exists: false,
        bytes: bytes,
        modified: File.mtime(path).rfc822,
        path: File.join('/', dropbox_path),
        is_dir: File.directory?(path),
        size: "#{bytes} bytes",
        root: "dropbox"
      }
      
      if File.directory?(path)
        metadata[:icon] = "folder"
        
        if list
          entries = Dir.entries(path).reject { |x| ['.', '..'].include? x }
          metadata[:contents] = entries.map do |entry|
            metadata(File.join(dropbox_path, entry))
          end
        end
      else
        metadata[:icon] = "page_white"
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
