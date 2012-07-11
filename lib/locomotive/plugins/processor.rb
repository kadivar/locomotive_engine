
module Locomotive
  module Plugins
    module Processor

      def run_plugin_before_filters
        enabled_plugins.each do |plugin|
          plugin.before_filters.each do |meth|
            plugin.send(meth)
          end
        end
      end

      def plugin_drops
        DropContainer.new({}.tap do |drops|
          enabled_plugins_hash.each do |id, plugin|
            drop = plugin.to_liquid
            arr[id] = drop if drop
          end
        end)
      end

      protected

      def enabled_plugins
        current_site.enabled_plugins.collect do |plugin_name|
          LocomotivePlugins.registered_plugins[plugin_name]
        end
      end

      def enabled_plugins_hash
        {}.tap do |h|
          current_site.enabled_plugins.collect do |plugin_name|
            h[plugin_name] = LocomotivePlugins.registered_plugins[plugin_name]
          end
        end
      end

    end
  end
end
