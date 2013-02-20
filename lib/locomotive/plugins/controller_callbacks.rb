
module Locomotive
  module Plugins
    module ControllerCallbacks

      protected

      # Around filter to prepare all plugin objects for request
      def prepare_plugins_for_request
        plugin_objects = current_site.enabled_plugin_objects_by_id.values
        self._process_callbacks_for_plugin_objects(plugin_objects) do
          yield
        end
      end

      def _process_callbacks_for_plugin_objects(plugin_objects)
        # Check if we have an object to process
        plugin_object = plugin_objects.shift
        unless plugin_object
          yield
          return
        end

        # Set controller
        plugin_object.controller = self

        # Call callbacks
        plugin_object.run_callbacks(:page_render) do
          self._process_callbacks_for_plugin_objects(plugin_objects) do
            yield
          end
        end
      end

      # Set up the liquid context object with plugin data
      def prepare_plugins_for_render
        current_site.enabled_plugin_objects_by_id.each do |plugin_id, plugin_object|
          plugin_object.setup_liquid_context(plugin_id, @liquid_context)
        end
      end

    end
  end
end
