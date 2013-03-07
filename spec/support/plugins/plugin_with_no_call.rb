class PluginWithNoCall
  include Locomotive::Plugin

  def self.rack_app
    RackApp
  end

  class RackApp
    def self.method_missing(meth, *args, &block)
      if meth == 'call'
        [200, {}, ['Rack app successful!']]
      else
        super
      end
    end
  end
end
