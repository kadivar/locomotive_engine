module Locomotive
  class SiteDataPresenter

    MODELS = %w{content_assets content_entries content_types pages snippets theme_assets}

    attr_reader :site, :ability

    def initialize(site, ability)
      @site = site
      @ability = ability
      @data = {}
    end

    def included_methods
      MODELS
    end

    ## Getters for each model ##

    MODELS.each do |model|
      define_method(model) do
        load_model_if_allowed(model)
      end
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

    ## Load the data for each model if allowed ##

    def load_model_if_allowed(model)
      return @data[model] if @data[model]

      if can_load?(model)
        @data[model] = self.send(:"load_#{model}")
      else
        nil
      end
    end

    def can_load?(model)
      object_to_authorize = "Locomotive::#{model.singularize.camelize}".constantize
      ability.can?(:index, object_to_authorize)
    end

    ## Methods to load the data ##

    MODELS.each do |model|
      define_method(:"load_#{model}") { site.send(model) }
    end

    # Override loading content entries
    def load_content_entries
      site.content_types.inject({}) do |h, content_type|
        h[content_type.slug] = content_type.entries
        h
      end
    end

  end
end
