
module Locomotive
  module Plugins
    module Loader

      def init_plugins
        initialize! unless @initialized

        if block_given?
          _in_init_block do
            yield
          end
        end
      end

      def bundler_require
        init_plugins do
          Bundler.require(:locomotive_plugins)
        end
      end

      protected

      def initialize!
        # Set up plugin class tracker
        Locomotive::Plugin.add_plugin_class_tracker do |plugin_class|
          added_plugin_class(plugin_class)
        end

        # Log warning for all plugins loaded before initialization
        Locomotive::Plugin.plugin_classes.each do |plugin_class|
          log_load_warning(plugin_class)
        end

        @initialized = true
      end

      def in_init_block?
        !!@in_init_block
      end

      def log_load_warning(plugin_class)
        Locomotive::Logger.warn("Plugin #{plugin_class} was loaded outside " +
          "the init_plugins block. It will not registered")
      end

      def valid_plugin_classes
        @valid_plugin_classes ||= Set.new
      end

      def added_plugin_class(plugin_class)
        if in_init_block?
          valid_plugin_classes << plugin_class
        else
          log_load_warning(plugin_class)
        end
      end

      # Override this to do custom initialization around init block. Always
      # call super so that other classes and modules may override as well
      def surround_init_block
        yield
      end

      def _in_init_block
        surround_init_block do
          begin
            @in_init_block = true
            yield
          ensure
            @in_init_block = false
          end
        end
      end

    end
  end
end
