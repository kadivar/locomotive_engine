class PluginWithNoCall
  include Locomotive::Plugin

  def self.rack_app
    RackApp
  end

  class SuperRackApp
    def self.call(env)
      [200, {}, ['Rack app successful!']]
    end
  end

  class RackApp < SuperRackApp
  end
end
