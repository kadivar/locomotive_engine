
module Locomotive
  module Middlewares
    class Plugins

      cattr_accessor :mountpoint_host
      cattr_accessor :current_rack_app_enabled

      def initialize(app)
        @app = app
      end

      def call(env)
        self.request = Rack::Request.new(env)

        response = nil
        set_mountpoint_host do
          set_rack_app_enabled do
            set_collection_name_prefix do
              response = @app.call(env)
            end
          end
        end
        response
      end

      def self.current_rack_app_enabled?
        self.current_rack_app_enabled
      end

      def current_rack_app_enabled?
        self.class.current_rack_app_enabled?
      end

      protected

      attr_accessor :request

      def site
        @site ||= fetch_site
      end

      def fetch_site
        query = Locomotive::Site.all

        if Locomotive.config.multi_sites?
          query = query.match_domain(request.host)
        end

        query.first
      end

      def set_mountpoint_host
        old_mountpoint_host = self.mountpoint_host
        self.mountpoint_host = "#{request.scheme}://#{request.host_with_port}"
        yield
      ensure
        self.mountpoint_host = old_mountpoint_host
      end

      def set_rack_app_enabled
        plugin_id = Locomotive::Plugins::Mounter.plugin_id_for_rack_app_path(request.path)
        old_value = current_rack_app_enabled
        if site
          self.current_rack_app_enabled =
            !!site.enabled_plugin_objects_by_id[plugin_id]
        end
        yield
      ensure
        self.current_rack_app_enabled = old_value
      end

      def set_collection_name_prefix
        if site
          ::Mongoid::Collections.with_collection_name_prefix("#{site.id}__") do
            yield
          end
        else
          yield
        end
      end

    end
  end
end
