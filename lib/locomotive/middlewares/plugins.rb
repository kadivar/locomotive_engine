
module Locomotive
  module Middlewares
    class Plugins

      include Locomotive::Routing::SiteDispatcher

      def initialize(app, opts = {})
        @app = app
      end

      def call(env)
        @env = env
        if current_site
          ::Mongoid::Collections.with_collection_name_prefix("#{current_site.id}__") do
            @app.call(env)
          end
        else
          @app.call(env)
        end
      end

      def request
        Rack::Request.new(@env)
      end

    end
  end
end
