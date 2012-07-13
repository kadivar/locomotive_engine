
module Locomotive
  module Plugins
    module Processor

      attr_accessor :plugin_drops_container

      attr_accessor :plugin_scope_hash

      def process_plugins
        plugin_drops_container_hash = {}
        self.plugin_scope_hash = { '$and' => [] }
        enabled_plugins do |plugin_id, plugin|
          plugin.controller = self

          # Call all before_filters
          plugin.before_filters.each do |meth|
            plugin.send(meth)
          end

          # Add the drop to the container
          drop = plugin.to_liquid
          plugin_drops_container_hash[plugin_id] = drop if drop

          # Add the scope to the hash
          scope = plugin.content_entry_scope
          self.plugin_scope_hash['$and'] << scope if scope
        end

        self.plugin_drops_container = DropContainer.new(plugin_drops_container_hash)
      end

      protected

      def enabled_plugins
        current_site.enabled_plugins.each do |plugin_id|
          plugin = LocomotivePlugins.registered_plugins[plugin_id]
          yield plugin_id, plugin
        end
      end

    end
  end
end
