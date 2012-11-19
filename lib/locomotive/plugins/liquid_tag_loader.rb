
module Locomotive
  module Plugins
    class LiquidTagLoader

      # Load and register all prefixed plugin tags
      def self.load
        LocomotivePlugins.registered_plugins.each do |plugin_id, plugin_class|
          plugin_class.prefixed_liquid_tags(plugin_id).each do |tag_name, tag_class|
            ::Liquid::Template.register_tag(tag_name, tag_class)
          end
        end
      end

    end
  end
end
