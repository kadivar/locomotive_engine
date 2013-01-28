
module Locomotive
  module Middlewares
    class Plugins

      include Locomotive::Routing::SiteDispatcher

      def initialize(app, opts = {})
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        site_id = fetch_site_id(request.host)

        if site_id
          ::Mongoid::Collections.with_collection_name_prefix("#{site_id}__") do
            @app.call(env)
          end
        else
          @app.call(env)
        end
      end

      def fetch_site_id(host)
        query = Locomotive::Site.only(:id)

        if Locomotive.config.multi_sites?
          query = query.match_domain(host)
        end

        query.first.try(:id)
      end

    end
  end
end
