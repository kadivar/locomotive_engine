class PluginWithProc
  include Locomotive::Plugin

  def self.rack_app
    Proc.new do |env|
      [200, {}, ['Rack app successful!']]
    end
  end
end
