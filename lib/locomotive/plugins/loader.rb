
module Locomotive

  def self.init_plugins(*args, &block)
    Locomotive::Plugins::Loader.init_plugins(*args, &block)
  end

  module Plugins
    module Loader

      @valid_plugin_classes = []

      def self.init_plugins
        initialize! unless @initialized

        if block_given?
          _in_init_block do
            yield
          end
        end
      end

      def self.in_init_block?
        !!@in_init_block
      end

      def self.bundler_require
        self.init_plugins do
          Bundler.require(:locomotive_plugins)
        end
      end

      protected

      def self.initialize!
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

      def self.log_load_warning(plugin_class)
        Locomotive::Logger.warn("Plugin #{plugin_class} was loaded outside " +
          "the init_plugins block. It will not registered")
      end

      def self.added_plugin_class(plugin_class)
        if in_init_block?
          @valid_plugin_classes << plugin_class
        else
          self.log_load_warning(plugin_class)
        end
      end

      # Override this to do custom initialization around init block. Always
      # call super so that other classes and modules may override as well
      def self.surround_init_block
        yield
      end

      def self._in_init_block
        self.surround_init_block do
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
