
module Locomotive
  module Plugins
    module Registration

      def registered_plugins
        @registered_plugins ||= {}
      end

      def register_plugin!(plugin_class)
        plugin_id = plugin_class.default_plugin_id
        registered_plugins[plugin_id] = plugin_class
        plugin_id
      end

    end
  end
end
