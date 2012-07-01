module FakeDropbox
  module Config
    class << self
      attr_accessor :authorize_request_token
      attr_accessor :authorize_access_token
    end

    self.authorize_request_token = true
    self.authorize_access_token = true
  end
end
