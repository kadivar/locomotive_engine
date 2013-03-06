
module Locomotive
  module Plugins
    module Mounter

      def self.mountpoint_for_plugin_id(plugin_id)
        mountpoint_host = Middlewares::Plugins.mountpoint_host
        "#{mountpoint_host}#{self.mount_path_for_plugin_id(plugin_id)}"
      end

      def self.mount_plugin_rack_apps(router)
        Locomotive::Plugins.registered_plugins.each do |plugin_id, plugin_class|
          app = plugin_class.mounted_rack_app
          if app
            setup_app!(app)
            router.mount(app => mount_path_for_plugin_id(plugin_id))
          end
        end
      end

      def self.plugin_id_for_rack_app_path(path)
        if path =~ %r{\A#{mount_path_prefix}([^/]+)}
          $1
        else
          nil
        end
      end

      protected

      def self.mount_path_prefix
        '/locomotive/plugins/'
      end

      def self.mount_path_for_plugin_id(plugin_id)
        "#{mount_path_prefix}#{plugin_id}"
      end

      # Set up the rack app so that its call method first checks to see if the
      # plugin is enabled.
      def self.setup_app!(app)
        app.instance_eval do
          # To ensure that our new call method is called before any other, we
          # need to put it directly on the singleton class. If that's where the
          # call method is already located, then we need to grab the old method
          # first so that we can call it
          def _setup_call_method!
            if singleton_methods.include?(:call)
              old_call_method = public_method(:call)
            end

            define_singleton_method(:call) do |env|
              if Middlewares::Plugins.current_rack_app_enabled?
                if old_call_method
                  old_call_method.call(env)
                else
                  super(env)
                end
              else
                [404, {'X-Cascade' => 'pass'}, []]
              end
            end
          end
        end
        app._setup_call_method!
      end

    end
  end
end
