module Locomotive
  class SiteDataPresenter

    # The models which are handled by this class in the order that they must
    # be created. Only the models which don't require special functionality
    # are included
    ORDERED_NORMAL_MODELS = %w{content_assets theme_assets snippets content_types pages}

    # All models handled by this class
    MODELS = ORDERED_NORMAL_MODELS + %w{content_entries}

    attr_reader :site, :ability, :errors

    def initialize(site, ability, attributes = nil)
      @site = site
      @ability = ability
      @data = {}
      self.build_models(attributes) if attributes
    end

    def self.all(site, ability)
      obj = self.new(site, ability)
      obj.send(:load_all_data)
      obj
    end

    def included_methods
      MODELS
    end

    ## Getters for each model ##

    MODELS.each do |model|
      define_method(model) { @data[model] ||= [] }
    end

    def content_entries
      @data['content_entries'] ||= Hash.new { |h, k| h[k] = [] }
    end

    ## Validity ##

    def valid?
      all_valid = true
      ORDERED_NORMAL_MODELS.each do |model|
        objects = self.send(:"#{model}")
        objects.each_with_index do |obj, index|
          unless obj.valid?
            all_valid = false
            add_errors(obj, model, index)
          end
        end
      end

      self.content_entries.each do |content_type_slug, entries|
        entries.each_with_index do |obj, index|
          if obj.content_type
            unless obj.valid?
              all_valid = false
              add_errors(obj, 'content_entries', content_type_slug, index)
            end
          else
            all_valid = false
            add_errors('content type does not exist', 'content_entries',
                       content_type_slug)
          end
        end
      end

      all_valid
    end

    ## Build models ##

    def build_models(all_attributes)
      # Need to build them in a particular order so all dependencies are met
      ORDERED_NORMAL_MODELS.each do |model|
        attributes_list = all_attributes[model]
        attributes_list.try(:each) do |attributes|
          self.send(:"build_#{model.singularize}_object", attributes)
        end
      end

      # Grab all the content types by slug. This includes newly created
      # content types, as well as the ones in the database
      content_types_by_slug = {}
      (self.content_types + site.content_types).each do |content_type|
        content_type.send(:normalize_slug) unless content_type.slug
        content_types_by_slug[content_type.slug] ||= content_type
      end

      all_attributes['content_entries'].each do |content_type_slug, attributes_list|
        content_type = content_types_by_slug[content_type_slug]

        if content_type
          # Make sure it has a label field and the custom fields have names
          content_type.entries_custom_fields.each do |field|
            field.send(:set_name)
          end
          content_type.send(:set_label_field) unless content_type.label_field_id

          attributes_list.each_with_index do |attributes, index|
            build_content_entry_object(content_type, attributes)
          end
        else
          build_content_entry_without_type(content_type_slug)
        end
      end
    end

    ## Save all objects ##

    def save
      if self.valid?
        ORDERED_NORMAL_MODELS.each do |model|
          self.send(:"#{model}").each { |obj| obj.save! }
        end
        self.content_entries.each do |_, entries|
          entries.each { |obj| obj.save! }
        end
      else
        false
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

    ## Validity and errors ##

    attr_accessor :valid

    def add_errors(model_or_string, *path)
      @errors ||= {}
      @errors['errors'] ||= {}

      is_string = model_or_string.kind_of?(String)

      # Build path
      current_container = @errors['errors']
      path.each_with_index do |element, index|
        if index == path.length - 1 && is_string
          current_container[element] ||= []
        else
          current_container[element] ||= {}
        end
        current_container = current_container[element]
      end

      # Add error messages
      if is_string
        current_container << model_or_string
      else
        model_or_string.errors.messages.each do |k, v|
          current_container[k] ||= []
          current_container[k] += v
        end
      end
    end

    ## Load the data for each model ##

    def load_all_data
      MODELS.each { |model| load_model_if_allowed(model) }
    end

    def load_model_if_allowed(model)
      if can_load?(model)
        @data[model] = self.send(:"load_#{model}")
      else
        nil
      end
    end

    def can_load?(model)
      object_to_authorize = "Locomotive::#{model.singularize.camelize}".constantize
      ability.can?(:read, object_to_authorize)
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

    MODELS.each do |model|
      define_method(:"build_#{model.singularize}_object") do |attributes|
        model_collection = site.send(:"#{model}")
        obj = model_collection.build
        obj.to_presenter.assign_attributes(attributes)
        self.send(:"#{model}") << obj
      end
    end

    # Override building content_entry
    def build_content_entry_object(content_type, attributes)
      obj = content_type.entries.build
      obj.to_presenter.assign_attributes(attributes)
      self.content_entries[content_type.slug] << obj
    end

    def build_content_entry_without_type(content_type_slug)
      self.content_entries[content_type_slug] << Locomotive::ContentEntry.new
    end

  end
end
