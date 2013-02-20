
module Locomotive
  module Middlewares
    module Plugins
      class CollectionPrefix

        def initialize(app, opts = {})
          @app = app
        end

        def call(env)
          request = Rack::Request.new(env)
          site_id = fetch_site_id(request.host)

          ret = nil
          if site_id
            ::Mongoid::Collections.with_collection_name_prefix("#{site_id}__") do
              ret = @app.call(env)
            end
          else
            ret = @app.call(env)
          end

          ret
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
end
