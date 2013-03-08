class PluginWithRackApp
  include Locomotive::Plugin

  def self.rack_app
    RackApp
  end

  class RackApp
    class << self
      attr_accessor :block
    end

    def self.call(env)
      rack_app_called
      block.call if block
      [200, {}, ['Rack app successful!']]
    end

    def self.rack_app_called
      # Just a stub to make sure it's being called
    end
  end

  before_rack_app_request :before_request
  def before_request
    # This should be called before the rack app is called
  end
end
