
module Locomotive
  module Middlewares
    class Plugins

      cattr_accessor :mountpoint_host

      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        site_id = fetch_site_id(request.host)

        response = nil
        set_mountpoint_host(request) do
          set_collection_name_prefix(site_id) do
            response = @app.call(env)
          end
        end
        response
      end

      protected

      def set_mountpoint_host(request)
        old_mountpoint_host = self.mountpoint_host
        self.mountpoint_host = "#{request.scheme}://#{request.host_with_port}"
        yield
      ensure
        self.mountpoint_host = old_mountpoint_host
      end

      def fetch_site_id(host)
        query = Locomotive::Site.only(:id)

        if Locomotive.config.multi_sites?
          query = query.match_domain(host)
        end

        query.first.try(:id)
      end

      def set_collection_name_prefix(site_id)
        if site_id
          ::Mongoid::Collections.with_collection_name_prefix("#{site_id}__") do
            yield
          end
        else
          yield
        end
      end

    end
  end
end
