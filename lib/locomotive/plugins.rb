
Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '**', '*.rb')) do |f|
  require f
end

module Locomotive
  module Plugins

    extend Registration

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

      # Log a warning for all plugins loaded before initialization
      Locomotive::Plugin.plugin_classes.each do |plugin_class|
        log_load_warning(plugin_class)
      end

      # Add tracker for new mongoid models
      ::Mongoid::Document.add_tracker do |model_class|
        _added_mongoid_model(model_class)
      end

      @initialized = true
    end

    def self.in_init_block?
      !!@in_init_block
    end

    def self.log_load_warning(plugin_class)
      Locomotive::Logger.warn("Plugin #{plugin_class} was loaded outside " +
        "the init_plugins block. It will not registered")
    end

    # Register tags
    def self.load_tags!(plugin_id, plugin_class)
      plugin_class.register_tags(plugin_id)
    end

    def self.handle_added_plugin_class(plugin_class)
      plugin_id = register_plugin!(plugin_class)
      load_tags!(plugin_id, plugin_class)
    end

    def self.handle_added_mongoid_model(model_class)
      model_class.use_collection_name_prefix = true
    end

    def self._added_plugin_class(plugin_class)
      if in_init_block?
        @defined_plugins << plugin_class
      else
        log_load_warning(plugin_class)
      end
    end

    def self._added_mongoid_model(model_class)
      if in_init_block?
        @mongoid_models << model_class
      end
    end

    def self._in_init_block
      begin
        @in_init_block = true
        @defined_plugins = []
        @mongoid_models = []
        yield
        @defined_plugins.each do |plugin_class|
          handle_added_plugin_class(plugin_class)
        end
        @mongoid_models.each do |model_class|
          handle_added_mongoid_model(model_class)
        end
      ensure
        @in_init_block = false
        @defined_plugins = nil
        @mongoid_models = nil
      end
    end

  end
end

# After we're all done, require our plugins
Locomotive::Plugins.bundler_require
