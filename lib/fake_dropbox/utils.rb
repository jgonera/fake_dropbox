require 'time'

module FakeDropbox
  module Utils
    def metadata(dropbox_path, list_contents = false)
      Entry.new(@dropbox_dir, dropbox_path).metadata(list_contents)
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
