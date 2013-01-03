
module Locomotive
  module Plugins
    module Registration

      def register_plugin_classes!(plugin_classes)
        plugin_classes.each do |plugin_class|
          register!(plugin_class)
        end
      end

      def registered_plugins
        @registered_plugins ||= {}
      end

      protected

      def register!(plugin_class)
        registered_plugins[plugin_class.default_plugin_id] = plugin_class
      end

    end
  end
end
