require 'fake_dropbox/utils'

module FakeDropbox
  module Config
    class << self
      include FakeDropbox::Utils

      attr_accessor :authorize_request_token
      attr_accessor :authorize_access_token
      attr_accessor :authorized
      attr_accessor :debug

      def reset!
        @authorize_request_token = true
        @authorize_access_token = true
        @authorized = true
        @debug = to_bool ENV['DROPBOX_DEBUG']
      end
    end

    reset!
  end
end
