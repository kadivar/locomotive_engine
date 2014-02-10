module Locomotive
  class CurrentSiteController < BaseController

    sections 'settings', 'site'

    localized

    skip_load_and_authorize_resource

    load_and_authorize_resource class: 'Site'

    helper 'Locomotive::Sites'

    before_filter :load_site

    before_filter :filter_attributes

    before_filter :ensure_domains_list, only: :update

    before_filter :load_plugins

    respond_to :json, only: :update

    def edit
      respond_with @site
    end

    def update
      @site.update_attributes(params[:site])
      respond_with @site, location: edit_current_site_path(new_host_if_subdomain_changed)
    end

    protected

    def load_site
      @site = current_site
    end

    def filter_attributes
      unless can?(:manage, Locomotive::Membership)
        params[:site].delete(:memberships_attributes) if params[:site]
      end

      filter_plugin_params if params[:site].try(:[], :plugins)
    end

    def filter_plugin_params
      # Check each plugin
      params[:site][:plugins].each do |index, plugin_hash|
        plugin_data = @site.plugin_data.where(plugin_id: plugin_hash[:plugin_id]).first
        unless can?(:enable, plugin_data)
          plugin_hash.delete(:plugin_enabled)
        end
        unless can?(:configure, plugin_data)
          plugin_hash.delete(:plugin_config)
        end
      end
    end

    def new_host_if_subdomain_changed
      if !Locomotive.config.manage_subdomain? || @site.domains.include?(request.host)
        {}
      else
        { host: site_url(@site, { fullpath: false, protocol: false }) }
      end
    end

    def ensure_domains_list
      params[:site][:domains] = [] unless params[:site][:domains]
    end

    def load_plugins
      @plugin_objects_by_id = @site.all_plugin_objects_by_id
      @plugin_data_by_id = @site.plugin_data.inject({}) do |h, plugin_data|
        h[plugin_data.plugin_id] = plugin_data
        h
      end
    end

  end
end
