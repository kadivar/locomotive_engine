
module Locomotive
  module Plugins
    class RackAppPassthrough

      def self.call(env)
        request = Rack::Request.new(env)

        site = fetch_site(request.host)
        plugin_id = env['action_dispatch.request.path_parameters'][:plugin_id]
        plugin_data = site.plugin_data.where(plugin_id: plugin_id).first
        app = plugin_data.plugin_class.rack_app if plugin_data

        if app && plugin_data.enabled
          app.call(env)
        else
          [404, {'X-Cascade' => 'pass'}, []]
        end
      end

      protected

      def self.fetch_site(host)
        query = Locomotive::Site.all

        if Locomotive.config.multi_sites?
          query = query.match_domain(host)
        end

        query.first
      end

    end
  end
end
