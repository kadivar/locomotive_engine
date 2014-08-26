
Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '**', '*.rb')) do |f|
  require f
end

module Locomotive
  module Plugins

    extend Registration
    extend JS3
    extend Helper

    def self.init_plugins
      raise 'Cannot nest init_plugins block' if in_init_block?

      initialize! unless @initialized

      if block_given?
        _in_init_block do
          yield
        end
      end
    end

    def self.bundler_require
      init_plugins do
        Bundler.require(:locomotive_plugins)
      end
    end

    def self.do_all_load_init
      Locomotive::Plugins.registered_plugins.each do |plugin_id, plugin_class|
        plugin_class.do_load_initialization
      end
    end

    protected

    def self.initialize!
      # Set up plugin class tracker
      Locomotive::Plugin.add_plugin_class_tracker do |plugin_class|
        _added_plugin_class(plugin_class)
      end

      @initialized = true
    end

    def self.in_init_block?
      !!@in_init_block
    end

    # Register tags
    def self.load_tags!(plugin_id, plugin_class)
      plugin_class.register_tags(plugin_id)
    end

    def self.handle_added_plugin_class(plugin_class)
      plugin_id = register_plugin!(plugin_class)
      load_tags!(plugin_id, plugin_class)
      add_javascript_context(plugin_id, plugin_class)
    end

    def self._added_plugin_class(plugin_class)
      if in_init_block?
        @defined_plugins << plugin_class
      end
    end

    def self._in_init_block
      begin
        @in_init_block = true
        @defined_plugins = []
        yield
        @defined_plugins.each do |plugin_class|
          handle_added_plugin_class(plugin_class)
        end
      ensure
        @in_init_block = false
        @defined_plugins = nil
      end
    end

  end
end

# After we're all done, require our plugins
Locomotive::Plugins.bundler_require
