module FakeDropbox
  module Config
    class << self
      attr_accessor :authorize_request_token
      attr_accessor :authorize_access_token
      attr_accessor :authorized

      def reset!
        @authorize_request_token = true
        @authorize_access_token = true
        @authorized = true
      end
    end

    reset!
  end
end
