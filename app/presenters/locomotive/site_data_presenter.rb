module Locomotive
  class SiteDataPresenter

    attr_reader :site, :ability

    def initialize(site, ability)
      @site = site
      @ability = ability
    end

    def included_methods
      %w(content_assets content_entries content_types current_site pages snippets theme_assets)
    end

    # Getters for each model (TODO: dry this up)

    def content_assets
      @content_assets ||= load_content_assets if ability.can?(:index, ContentAsset)
    end

    def content_entries
      @content_entries ||= load_content_entries if ability.can?(:index, ContentEntry)
    end

    def content_types
      @content_types ||= load_content_types if ability.can?(:index, ContentType)
    end

    def current_site
      @current_site ||= load_current_site if ability.can?(:index, site)
    end

    def pages
      @pages ||= load_pages if ability.can?(:index, Page)
    end

    def snippets
      @snippets ||= load_snippets if ability.can?(:index, Snippet)
    end

    def theme_assets
      @theme_assets ||= load_theme_assets if ability.can?(:index, ThemeAsset)
    end

    def as_json(methods = nil)
      methods ||= self.included_methods
      {}.tap do |hash|
        methods.each do |meth|
          hash[meth] = self.send(meth.to_sym) rescue nil
        end
      end
    end

    protected

    def load_content_assets
      site.content_assets
    end

    def load_content_entries
      site.content_types.inject({}) do |h, content_type|
        h[content_type.slug] = content_type.entries
        h
      end
    end

    def load_content_types
      site.content_types
    end

    def load_current_site
      site
    end

    def load_pages
      site.pages
    end

    def load_snippets
      site.snippets
    end

    def load_theme_assets
      site.theme_assets
    end

  end
end
