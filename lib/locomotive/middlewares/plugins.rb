
module Locomotive
  module Middlewares
    class Plugins

      cattr_accessor :current_site
      cattr_accessor :plugin_id
      cattr_accessor :mountpoint_host
      cattr_accessor :current_rack_app_enabled

      def initialize(app)
        @app = app
      end

      def call(env)
        self.request = Rack::Request.new(env)

        response = nil
        set_current_site do
          set_plugin_id do
            set_mountpoint_host do
              set_rack_app_enabled do
                set_collection_name_prefix do
                  response = @app.call(env)
                end
              end
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

      def fetch_site
        query = Locomotive::Site.all

        if Locomotive.config.multi_sites?
          query = query.match_domain(request.host)
        end

        query.first
      end

      def set_current_site
        old_site = self.current_site
        self.current_site = fetch_site
        yield
      ensure
        self.current_site = old_site
      end

      def set_plugin_id
        old_plugin_id = self.plugin_id
        self.plugin_id = \
          Locomotive::Plugins::Mounter.plugin_id_for_rack_app_path(request.path)
        yield
      ensure
        self.plugin_id = old_plugin_id
      end

      def set_mountpoint_host
        old_mountpoint_host = self.mountpoint_host
        self.mountpoint_host = "#{request.scheme}://#{request.host_with_port}"
        yield
      ensure
        self.mountpoint_host = old_mountpoint_host
      end

      def set_rack_app_enabled
        old_value = current_rack_app_enabled
        if current_site
          self.current_rack_app_enabled =
            !!current_site.enabled_plugin_objects_by_id[self.plugin_id]
        end
        yield
      ensure
        self.current_rack_app_enabled = old_value
      end

      def set_collection_name_prefix
        if current_site
          ::Mongoid::Sessions.with_collection_name_prefix("#{current_site.id}__") do
            yield
          end
        else
          yield
        end
      end

    end
  end
end
