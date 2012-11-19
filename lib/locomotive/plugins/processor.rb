
module Locomotive
  module Plugins
    module Processor

      protected

      attr_accessor :plugin_drops_container

      # An around_filter to work with plugins
      def process_plugins
        plugin_drops_container_hash = {}
        current_site.enabled_plugin_objects_by_id.each do |plugin_id, plugin|
          plugin.controller = self

          # Call all before_filters
          plugin.before_filters.each do |meth|
            plugin.send(meth)
          end

          # Add the drop to the container
          drop = plugin.to_liquid
          plugin_drops_container_hash[plugin_id] = drop if drop
        end

        self.plugin_drops_container = DropContainer.new(plugin_drops_container_hash)

        yield

        current_site.enabled_plugin_objects_by_id.each do |plugin_id, plugin|
          plugin.save_db_model_container
        end
      end

      # Add all plugin data to the liquid context object
      def add_plugin_data_to_liquid_context(context)
        enabled_plugin_tags = Set.new.tap do |set|
          current_site.enabled_plugin_objects_by_id.each do |plugin_id, plugin_object|
            set.merge(plugin_object.class.prefixed_liquid_tags(plugin_id).values)
          end
        end

        # Add registers
        context.registers.merge!({
          :plugins => current_site.enabled_plugin_objects_by_id.values,
          :enabled_plugin_tags => enabled_plugin_tags
        })

        # Add drops
        context['plugins'] = self.plugin_drops_container

        # Add filters
        context.add_filters(current_site.plugin_liquid_filters)
      end

    end
  end
end
