
module Locomotive
  module Plugins
    module Processor

      attr_accessor :plugin_drops_container

      def process_plugins
        self.plugin_drops_container = DropContainer.new({}.tap do |container|
          enabled_plugins do |plugin_id, plugin|
            plugin.before_filters.each do |meth|
              plugin.send(meth)
            end
            drop = plugin.to_liquid
            container[plugin_id] = drop if drop
          end
        end)
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
