
module Locomotive
  module Plugins
    module Processor

      attr_accessor :plugin_drops_container

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
      end

      # All enabled plugin objects for this site. These are put in a liquid
      # register
      def plugins
        current_site.enabled_plugin_objects_by_id.values
      end

    end
  end
end
