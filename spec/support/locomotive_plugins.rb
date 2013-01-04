
module Locomotive
  module Plugins
    module SpecHelpers

      def self.before_each
        clear_plugins!
        setup_load_path!
      end

      def self.clear_plugins!
        Locomotive::Plugins.instance_variable_set(:@initialized, nil)
        Locomotive::Plugins.instance_variable_set(:@registered_plugins, nil)
        Locomotive::Plugin.instance_variable_set(:@trackers, [])
        Locomotive::Plugin.instance_variable_set(:@plugin_classes, Set.new)
      end

      def self.stub_registered_plugins(*plugin_classes)
        registered_plugins = plugin_classes.inject({}) do |h, plugin_class|
          h[plugin_class.default_plugin_id] = plugin_class
          h
        end

        # Set an instance variable instead of traditional stubbing. This way it
        # will get reset between tests
        Locomotive::Plugins.instance_variable_set(:@registered_plugins,
          registered_plugins)
      end

      def self.setup_load_path!
        $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib',
          'locomotive', 'plugins', 'plugins_spec_files'))
      end

    end
  end
end
