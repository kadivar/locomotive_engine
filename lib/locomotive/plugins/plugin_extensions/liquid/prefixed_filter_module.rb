
module Locomotive
  module Plugin
    module Liquid
      module PrefixedFilterModule

        protected

        # Put the appropriate plugin_object in the liquid context. Note that
        # the prefix is the plugin_id
        def filter_method_called(prefix, meth)
          helper = ::Locomotive::Plugins::LiquidContextHelpers
          helper.add_plugin_object_to_context(prefix, @context) do
            yield
          end
        end

      end
    end
  end
end
