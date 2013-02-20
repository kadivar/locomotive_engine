
module Locomotive
  module Plugins
    module SpecHelpers

      def self.define_plugins(context, &block)
        @define_plugins_blocks ||= {}
        @define_plugins_blocks[context] = block
      end

      def self.before_each(*contexts)
        clear_plugins!
        setup_load_path!
        load_defined_plugins!(*contexts)
        begin
          Locomotive::Plugins.do_all_load_init
        rescue
          # Stub the error
        end
      end

      def self.clear_plugins!
        Locomotive::Plugins.instance_variable_set(:@initialized, nil)
        Locomotive::Plugins.instance_variable_set(:@registered_plugins, nil)
        Locomotive::Plugin.instance_variable_set(:@trackers, [])
        Locomotive::Plugin.instance_variable_set(:@plugin_classes, Set.new)
      end

      def self.setup_load_path!
        $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib',
          'locomotive', 'plugins', 'plugins_spec_files'))
      end

      def self.load_defined_plugins!(*contexts)
        contexts.each do |context|
          Plugins.init_plugins do
            @define_plugins_blocks[context].try(:call)
          end
        end
      end

    end
  end
end
