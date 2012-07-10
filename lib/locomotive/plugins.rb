
module Locomotive
  module PluginProcessor

    def run_plugin_before_filters
      enabled_plugins.each do |plugin|
        plugin.before_filters.each do |meth|
          plugin.send(meth)
        end
      end
    end

    protected

    def enabled_plugins
      current_site.enabled_plugins.collect do |plugin_name|
        LocomotivePlugins.registered_plugins[plugin_name]
      end
    end

  end
end
