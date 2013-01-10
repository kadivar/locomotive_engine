
module Locomotive
  module Plugins
    module Registration

      def registered_plugins
        @registered_plugins ||= {}
      end

      def register_plugin!(plugin_class)
        plugin_id = plugin_class.default_plugin_id
        if registered_plugins[plugin_id]
          raise %{Already registered plugin with id "#{plugin_id}"}
        else
          registered_plugins[plugin_id] = plugin_class
        end
        plugin_id
      end

    end
  end
end
