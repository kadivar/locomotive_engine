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

    ## Create models ##

    def create_models(all_attributes)
      # TODO: need to deal with errors (i.e. don't save *anything* if we have an error)

      # Need to create them in a particular order so all dependencies are met
      %w{content_assets theme_assets snippets content_types pages}.each do |model|
        attributes_list = all_attributes[model]
        attributes_list.try(:each) do |attributes|
          obj = self.send(:"build_#{model.singularize}_object")
          presenter = obj.to_presenter
          success = presenter.update_attributes(attributes)
        end
      end

      all_attributes['content_entries'].each do |content_type_slug, attributes_list|
        attributes_list.each do |attributes|
          obj = build_content_entry_object(Locomotive::ContentType.where(:slug => content_type_slug).first)
          presenter = obj.to_presenter
          presenter.update_attributes(attributes)
        end
      end
    end

    ## JSON to return ##

    def to_json(options = {})
      self.as_json(options).to_json
    end

    def as_json(options = {})
      methods = self.included_methods
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

    ## Build object in a model ##

    (MODELS - %w{content_entries}).each do |model|
      define_method(:"build_#{model.singularize}_object") do
        model_collection = site.send(:"#{model}")
        model_collection.build
      end
    end

    # Override building content_entry
    def build_content_entry_object(content_type)
      content_type.entries.build
    end

  end
end
