module FakeDropbox
  module Utils
    DATE_FORMAT = '%a, %d %b %Y %H:%M:%S %z'
    
    def metadata(path, list=false)
      full_path = File.join(@dropbox_dir, path)
      path.insert(0, '/') if path[0] != '/'
      bytes = File.directory?(path) ? 0 : File.size(full_path)
      
      metadata = {
        thumb_exists: false,
        bytes: bytes,
        modified: File.mtime(full_path).strftime(DATE_FORMAT),
        path: path,
        is_dir: File.directory?(full_path),
        size: "#{bytes} bytes",
        root: "dropbox"
      }
      
      if File.directory?(full_path)
        metadata[:icon] = "folder"
        
        if list
          entries = Dir.entries(full_path).reject { |x| ['.', '..'].include? x }
          metadata[:contents] = entries.map do |entry|
            metadata(File.join(path, entry))
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
