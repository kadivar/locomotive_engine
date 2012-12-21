
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

=begin
        current_site.enabled_plugin_objects_by_id.each do |plugin_id, plugin|
          plugin.controller = self

          # Call all before_filters
          plugin.before_filters.each do |meth|
            plugin.send(meth)
          end

          # Add the drop to the container
          drop = plugin.to_liquid
          if drop
            drop.extend(DropExtension)
            drop.set_plugin_id(plugin_id)
            plugin_drops_container_hash[plugin_id] = drop
          end
        end

        self.plugin_drops_container = DropContainer.new(plugin_drops_container_hash)

        yield

        current_site.enabled_plugin_objects_by_id.each do |plugin_id, plugin|
          plugin.save_db_model_container
        end
=end

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
        plugin_object.run_callbacks(:filter) do
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

=begin
      # Add all plugin data to the liquid context object
      def add_plugin_data_to_liquid_context(context)
        enabled_plugin_tags = Set.new.tap do |set|
          current_site.enabled_plugin_objects_by_id.each do |plugin_id, plugin_object|
            set.merge(plugin_object.class.prefixed_liquid_tags(plugin_id).values)
          end
        end

        # Add tags
        context.registers[:enabled_plugin_tags] = enabled_plugin_tags

        # Add drops
        context['plugins'] = self.plugin_drops_container

        # Add filters
        context.add_filters(current_site.plugin_liquid_filters)
      end

    end
=end
    end
  end
end
