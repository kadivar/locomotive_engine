
module Locomotive
  module Plugins
    module SpecHelpers

      #def self.define_plugins(context, &block)
      #  @define_plugins_blocks ||= {}
      #  @define_plugins_blocks[context] = block
      #end

      #def self.before_each(*contexts)
      #  clear_plugins!
      #  setup_load_path!
      #  load_defined_plugins!(*contexts)
      #  begin
      #    Locomotive::Plugins.do_all_load_init
      #  rescue
      #    # Stub the error
      #  end
      #end
      #
      #def self.clear_plugins!
      #  Locomotive::Plugins.instance_variable_set(:@initialized, nil)
      #  Locomotive::Plugins.instance_variable_set(:@registered_plugins, nil)
      #  Locomotive::Plugin.instance_variable_set(:@trackers, [])
      #  Locomotive::Plugin.instance_variable_set(:@plugin_classes, Set.new)
      #end

      def self.unregister_plugin(plugin_id)
        Locomotive::Plugins.registered_plugins[plugin_id] = nil
      end

      def self.load_plugin(file, unregister_first = false, unregister_plugin_id = nil)
        ensure_setup_load_path
        if unregister_first
          unregister_plugin_id ||= file.sub(/\.rb$/, '')
          unregister_plugin(unregister_plugin_id)
        end
        load(file)
      end

      def self.load_all_plugins
        Dir.glob(File.join(plugins_path, '*.rb')) do |file|
          Locomotive::Plugins.init_plugins do
            load_plugin file
          end
        end
      end

      #def self.load_defined_plugins!(*contexts)
      #  contexts.each do |context|
      #    Plugins.init_plugins do
      #      @define_plugins_blocks[context].try(:call)
      #    end
      #  end
      #end

      protected

      def self.ensure_setup_load_path
        return if @done_setup_load_path
        self.setup_load_path!
        @done_setup_load_path = true
      end

      def self.setup_load_path!
        $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib',
          'locomotive', 'plugins', 'plugins_spec_files'))
      end

      def self.plugins_path
        File.join(File.dirname(__FILE__), '..', 'lib', 'locomotive',
          'plugins', 'plugins_spec_files')
      end

    end
  end
end
