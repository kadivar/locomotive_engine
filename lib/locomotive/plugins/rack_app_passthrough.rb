
module Locomotive
  module Plugins
    class RackAppPassthrough

      def initialize(plugin_id_path_param)
        @path_param = :"#{plugin_id_path_param}"
      end

      def call(env)
        app = get_app(env)
        if app
          app.call(env)
        else
          [404, {'X-Cascade' => 'pass'}, []]
        end
      end

      protected

      def fetch_site(host)
        query = Locomotive::Site.all

        if Locomotive.config.multi_sites?
          query = query.match_domain(host)
        end

        query.first
      end

      # Returns nil if app should not be called
      def get_app(env)
        request = Rack::Request.new(env)
        site = fetch_site(request.host)

        plugin_id = env['action_dispatch.request.path_parameters'][@path_param]
        plugin_object = site.enabled_plugin_objects_by_id[plugin_id]

        plugin_object.try(:prepared_rack_app)
      end

    end
  end
end
