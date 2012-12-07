
module Locomotive
  module Plugins
    module LiquidContextHelpers
      def self.add_plugin_object_to_context(plugin_id, context)
        old_value = context.registers[:plugin_object]
        obj = context.registers[:site].all_plugin_objects_by_id[plugin_id]
        context.registers[:plugin_object] = obj
        yield
        context.registers[:plugin_object] = old_value
      end
    end
  end
end
