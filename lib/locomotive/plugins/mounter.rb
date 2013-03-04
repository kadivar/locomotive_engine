
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
          setup_app!(app)
          router.mount(app => mount_path_for_plugin_id(plugin_id)) if app
        end
      end

      protected

      def self.mount_path_for_plugin_id(plugin_id)
        "/locomotive/plugins/#{plugin_id}"
      end

      def self.setup_app!(app)
        app.instance_eval do
          def call(env)
            [200, {}, ['Wahoo!!!']]
          end
        end
      end

    end
  end
end
