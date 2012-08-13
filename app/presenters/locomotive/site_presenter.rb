module Locomotive
  class SitePresenter < BasePresenter

    delegate :name, :locales, :enabled_plugin_ids, :subdomain, :domains, :robots_txt, :seo_title, :meta_keywords, :meta_description, :domains_without_subdomain, :to => :source

    def domain_name
      Locomotive.config.domain
    end

    def memberships
      self.source.memberships.map { |membership| membership.as_json(self.options) }
    end

    # TODO: don't want it here
    def available_plugins
      LocomotivePlugins.registered_plugins.keys.collect do |plugin_id|
        {
          :plugin_id => plugin_id,
          :plugin_name => EnabledPlugin.plugin_name(plugin_id)
        }
      end
    end

    def enabled_plugin_ids
      self.source.enabled_plugins.collect(&:plugin_id)
    end

    def included_methods
      super + %w(name locales enabled_plugin_ids domain_name subdomain domains robots_txt seo_title meta_keywords meta_description domains_without_subdomain memberships available_plugins)
    end

    def as_json_for_html_view
      methods = included_methods.clone - %w(memberships)
      self.as_json(methods)
    end

  end
end
