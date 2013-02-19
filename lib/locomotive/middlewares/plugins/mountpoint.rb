
module Locomotive
  module Middlewares
    module Plugins
      class Mountpoint

        cattr_accessor :mountpoint

        def initialize(app)
          @app = app
        end

        def call(env)
          request = Rack::Request.new(env)

          old_mountpoint = self.mountpoint
          self.mountpoint = "#{request.scheme}://#{request.host_with_port}"
          ret = @app.call(env)
          self.mountpoint = old_mountpoint

          ret
        end

        def self.mountpoint_for_plugin_id(plugin_id)
          "#{self.mountpoint}#{self.mount_path_for_plugin_id(plugin_id)}"
        end

        protected

        def self.mount_path_for_plugin_id(plugin_id)
          "/locomotive/plugins/#{plugin_id}"
        end

      end
    end
  end
end
