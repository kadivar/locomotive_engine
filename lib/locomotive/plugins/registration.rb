
module Locomotive
  module Plugins
    module Registration

      def registered_plugins
        @registered_plugins ||= {}
      end

      def register_plugin!(plugin_class)
        registered_plugins[plugin_class.default_plugin_id] = plugin_class
      end

    end
  end
end
