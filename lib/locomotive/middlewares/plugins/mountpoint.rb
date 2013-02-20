
module Locomotive
  module Middlewares
    module Plugins
      class Mountpoint

        cattr_accessor :mountpoint_host

        def initialize(app)
          @app = app
        end

        def call(env)
          request = Rack::Request.new(env)

          old_mountpoint_host = self.mountpoint_host
          self.mountpoint_host = "#{request.scheme}://#{request.host_with_port}"
          ret = @app.call(env)
          self.mountpoint_host = old_mountpoint_host

          ret
        end

      end
    end
  end
end
