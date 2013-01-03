
Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '**', '*.rb')) do |f|
  require f
end

module Locomotive
  module Plugins

    extend Loader
    extend Registration

    def self.register_plugins!
      register_plugin_classes!(valid_plugin_classes)
      registered_plugins.freeze
    end

  end
end
