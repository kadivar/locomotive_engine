module Locomotive
  class CurrentSiteController < BaseController

    sections 'settings', 'site'

    skip_load_and_authorize_resource

    load_and_authorize_resource :class => 'Site'

    helper 'Locomotive::Sites'

    before_filter :filter_attributes

    before_filter :load_plugins

    respond_to :json, :only => :update

    def edit
      @site = current_site
      respond_with @site
    end

    def update
      @site = current_site
      @site.update_attributes(params[:site])
      respond_with @site, :location => edit_current_site_url(new_host_if_subdomain_changed)
    end

    protected

    def filter_attributes
      unless can?(:manage, Locomotive::Membership)
        params[:site].delete(:memberships_attributes) if params[:site]
      end
    end

    def new_host_if_subdomain_changed
      if !Locomotive.config.manage_subdomain? || @site.domains.include?(request.host)
        {}
      else
        { :host => site_url(@site, { :fullpath => false, :protocol => false }) }
      end
    end

    def load_plugins
      # TODO: duplication in Locomotive::Plugins::Processor#each_plugin_with_id
      @plugins = current_site.enabled_plugins.collect do |enabled_plugin|
        plugin_id = enabled_plugin.plugin_id
        config = enabled_plugin.config
        LocomotivePlugins.registered_plugins[plugin_id].new(config)
      end
    end

  end
end
