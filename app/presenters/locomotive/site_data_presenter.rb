module Locomotive
  class SiteDataPresenter

    # The models which are handled by this class in the order that they must
    # be created. Only the models which don't require special functionality
    # are included
    ORDERED_NORMAL_MODELS = %w{content_assets theme_assets snippets content_types pages}

    # All models handled by this class
    MODELS = ORDERED_NORMAL_MODELS + %w{content_entries}

    attr_reader :site, :errors

    # If attributes are provided, use them to build the models (see
    # documentation fot build_models)
    def initialize(site, attributes = nil)
      @site = site
      @data = {}
      self.build_models(attributes) if attributes
    end

    # Load all data from the database
    def self.all(site)
      obj = self.new(site)
      obj.send(:load_data)
      obj
    end

    # Find all data according to the ids in the attributes. The attributes
    # should look like the following example:
    #
    # {
    #   :pages => {
    #     "4f832c2cb0d86d3f42000001" => {
    #       # Page attrbutes
    #     }
    #   },
    #   :content_entries => {
    #     :projects => {
    #       "4f832c2cb0d86d3f42000002" => {
    #         # Project attributes
    #       }
    #     }
    #   }
    # }
    def self.find_from_attributes(site, attributes)
      ids = {}

      ORDERED_NORMAL_MODELS.each do |model|
        ids[model] = (attributes[model] || {}).keys
      end

      ids['content_entries'] = {}
      (attributes['content_entries'] || []).each do |content_type_slug, entries|
        ids['content_entries'][content_type_slug] = entries.keys
      end

      self.find_from_ids(site, ids)
    end

    # Find all data according to the ids given. The ids should look like the
    # following example:
    #
    # {
    #   :pages => [
    #     "4f832c2cb0d86d3f42000001"
    #   ],
    #   :content_entries => {
    #     :projects => [
    #       "4f832c2cb0d86d3f42000002"
    #     ]
    #   }
    # }
    def self.find_from_ids(site, ids)
      obj = self.new(site)
      obj.send(:load_data, ids)
      obj
    end

    # Methods to use when building json object
    def included_methods
      MODELS
    end

    # Authorize action with loaded data
    def authorize!(ability, action)
      messages = []
      failed = false

      MODELS.each do |model|
        begin
          ability.authorize!(action, model_class(model))
        rescue CanCan::AccessDenied => e
          failed = true
          messages << e.message
        end
      end

      if failed
        raise CanCan::AccessDenied.new(messages)
      end
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
            id = obj.new_record? && index || obj.id
            add_errors(obj, model, id)
          end
        end
      end

      self.content_entries.each do |content_type_slug, entries|
        entries.each_with_index do |obj, index|
          if obj.content_type
            unless obj.valid?
              all_valid = false
              id = obj.new_record? && index || obj.id
              add_errors(obj, 'content_entries', content_type_slug, id)
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

    # Build models and assign their attributes. The attributes should look like
    # the following example:
    #
    # {
    #   :pages => [
    #     {
    #       # Page attrbutes
    #     }
    #   ],
    #   :content_entries => {
    #     :projects => [
    #       {
    #         # Project attributes
    #       }
    #     ]
    #   }
    # }
    def build_models(all_attributes)
      # Need to build them in a particular order so all dependencies are met
      ORDERED_NORMAL_MODELS.each do |model|
        attributes_list = all_attributes[model]
        attributes_list.try(:each) do |attributes|
          obj = self.send(:"build_#{model.singularize}_object")
          assign_attributes_to(obj, attributes)
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

          attributes_list.each do |attributes|
            obj = build_content_entry_object(content_type)
            assign_attributes_to(obj, attributes)
          end
        else
          build_content_entry_without_type(content_type_slug)
        end
      end
    end

    # Assign attributes to objects by id. The attributes should look like the
    # following example:
    #
    # {
    #   :pages => {
    #     "4f832c2cb0d86d3f42000001" => {
    #       # Page attributes
    #     }
    #   },
    #   :content_entries => {
    #     :projects => {
    #       "4f832c2cb0d86d3f42000002" => {
    #         # Project attributes
    #       }
    #     }
    #   }
    # }
    def assign_attributes(attributes)
      MODELS.each do |model|
        if attributes[model]
          if model == 'content_entries'
            self.content_entries.each do |content_type_slug, entries|
              entries.each do |obj|
                attributes_for_obj = attributes[model][content_type_slug][obj.id.to_s]
                if attributes_for_obj
                  assign_attributes_to(obj, attributes_for_obj)
                end
              end
            end
          else
            self.send(:"#{model}").each do |obj|
              attributes_for_obj = attributes[model][obj.id.to_s]
              if attributes_for_obj
                assign_attributes_to(obj, attributes_for_obj)
              end
            end
          end
        end
      end
    end

    # Destroy all loaded objects
    def destroy_all
      ORDERED_NORMAL_MODELS.each do |model|
        self.send(:"#{model}").each do |object|
          object.destroy
        end
      end
      self.content_entries.each do |content_type_slug, entries|
        entries.each do |object|
          object.destroy
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

    # Get the class for a model
    def model_class(model)
      "Locomotive::#{model.singularize.camelize}".constantize
    end

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

    def load_data(ids = :all)
      MODELS.each do |model|
        if ids == :all
          data = self.send(:"load_#{model}", ids)
        else
          data = self.send(:"load_#{model}", ids[model])
        end
        @data[model] = data
      end
    end

    ORDERED_NORMAL_MODELS.each do |model|
      define_method(:"load_#{model}") do |ids|
        if ids == :all
          site.send(model)
        else
          site.send(model).find(ids)
        end
      end
    end

    def load_content_entries(ids)
      ids ||= {}
      site.content_types.inject({}) do |h, content_type|
        content_type_slug = content_type.slug
        if ids == :all || ids[content_type_slug] == :all
          entries = content_type.entries
        else
          if ids[content_type_slug]
            entries = content_type.entries.find(ids[content_type_slug])
          end
        end
        h[content_type_slug] = entries if entries
        h
      end
    end

    ## Build object in a model ##

    MODELS.each do |model|
      define_method(:"build_#{model.singularize}_object") do
        model_collection = site.send(:"#{model}")
        obj = model_collection.build
        self.send(:"#{model}") << obj
        obj
      end
    end

    # Override building content_entry
    def build_content_entry_object(content_type)
      obj = content_type.entries.build
      self.content_entries[content_type.slug] << obj
      obj
    end

    def build_content_entry_without_type(content_type_slug)
      self.content_entries[content_type_slug] << Locomotive::ContentEntry.new
    end

    # Assign attributes to an object using its presenter
    def assign_attributes_to(obj, attributes)
      obj.to_presenter.assign_attributes(attributes)
    end

  end
end
