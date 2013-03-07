class PluginWithRackApp
  include Locomotive::Plugin

  def self.rack_app
    RackApp
  end

  class RackApp
    def self.call(env)
      [200, {}, ['Rack app successful!']]
    end
  end
end
