
module Locomotive
  module Plugin
    module Liquid
      module TagSubclassMethods

        protected

        # Put the appropriate plugin_object in the liquid context. Note that
        # the prefix is the plugin_id
        def rendering_tag(prefix, enabled, context)
          helper = ::Locomotive::Plugins::LiquidContextHelpers
          helper.add_plugin_object_to_context(prefix, context) do
            yield
          end
        end

      end
    end
  end
end
