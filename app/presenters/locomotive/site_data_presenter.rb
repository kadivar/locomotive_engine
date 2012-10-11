module Locomotive
  class SiteDataPresenter

    include Extensions::SiteDataPresenter::Authorization
    include Extensions::SiteDataPresenter::Load
    include Extensions::SiteDataPresenter::Validation

    attr_reader :site

    # If attributes are provided, use them to build the models (see
    # documentation for build_models)
    def initialize(site, attributes = nil)
      @site = site
      @data = {}
      self.build_models(attributes) if attributes
    end

    # Load all data from the database
    def self.all(site)
      obj = self.new(site)
      obj.load_data
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

      self.ordered_normal_models.each do |model|
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
      obj.load_data(ids)
      obj
    end

    # The models which are handled by this class in the order that they must
    # be created. Only the models which don't require special functionality
    # are included
    def self.ordered_normal_models
      %w{content_assets theme_assets snippets content_types pages}
    end

    # All models handled by this class
    def self.models
      ordered_normal_models + %w{content_entries}
    end

    %w{models ordered_normal_models}.each do |meth|
      define_method(:"#{meth}") { self.class.send(:"#{meth}") }
    end

    # Methods to use when building json object
    def included_methods
      self.class.models
    end

    ## Getters for each model ##

    self.ordered_normal_models.each do |model|
      define_method(model) { @data[model] ||= [] }
    end

    def content_entries
      @data['content_entries'] ||= Hash.new { |h, k| h[k] = [] }
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
      self.class.ordered_normal_models.each do |model|
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

      all_attributes['content_entries'].try(:each) do |content_type_slug, attributes_list|
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
      self.class.models.each do |model|
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
      self.class.ordered_normal_models.each do |model|
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

    # Mirror the current state with the given attributes
    def mirror(attributes)
      self.destroy_all
      @data = {}
      self.build_models(attributes)
    end

    ## Save all objects ##

    def save
      if self.valid?
        self.class.ordered_normal_models.each do |model|
          self.send(:"#{model}").each { |obj| presenter_for(obj).save }
        end
        self.content_entries.each do |_, entries|
          entries.each { |obj| presenter_for(obj).save }
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

    ## Build object in a model ##

    self.models.each do |model|
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
      presenter_for(obj).assign_attributes(attributes)
    end

    def presenter_for(obj)
      @presenters ||= {}
      @presenters[obj] ||= obj.to_presenter
    end

  end
end
