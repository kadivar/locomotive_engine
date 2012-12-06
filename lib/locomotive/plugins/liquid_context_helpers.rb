
module Locomotive
  module Plugins
    module LiquidContextHelpers

      protected

      def add_plugin_object_to_context(plugin_id)
        obj = @context.registers[:site].all_plugin_objects_by_id[plugin_id]
        @context.registers[:plugin_object] = obj
        yield
        @context.registers[:plugin_object]
      end
    end
  end
end
