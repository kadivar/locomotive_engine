
module Locomotive
  module Plugins
    module Mountpoint

      def self.mountpoint_for_plugin_id(plugin_id)
        mountpoint_host = Middlewares::Plugins::Mountpoint.mountpoint_host
        "#{mountpoint_host}#{self.mount_path_for_plugin_id(plugin_id)}"
      end

      def self.setup_plugins_rack_mountpoint(router)
        plugin_id_path_param = 'plugin_id'
        router.match self.mount_path_for_plugin_id(":#{plugin_id_path_param}"),
          anchor: false, format: false,
          to: Locomotive::Plugins::RackAppPassthrough.new(plugin_id_path_param)
      end

      protected

      def self.mount_path_for_plugin_id(plugin_id)
        "/locomotive/plugins/#{plugin_id}"
      end


    end
  end
end
