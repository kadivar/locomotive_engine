
module Locomotive
  module Plugin
    module Liquid
      module PrefixedFilterModule

        include Locomotive::Plugins::LiquidContextHelpers

        protected

        # Put the appropriate plugin_object in the liquid context. Note that
        # the prefix is the plugin_id
        def filter_method_called(prefix, meth)
          self.add_plugin_object_to_context(prefix) do
            yield
          end
        end

      end
    end
  end
end
