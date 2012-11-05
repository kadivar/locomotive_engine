module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        module MinimalSave

          protected

          # Minimally save all new records for the given model if the model
          # should be minimally saved. Set errors for the object if validation
          # fails. Returns true if there are no errors for this model after the
          # save
          def minimal_save_model(model)
            if should_minimally_save_model?(model)
              all_objects(false, model) do |obj, model, *path|
                if obj.new_record?
                  if model == 'content_entries' && !obj.content_type
                    content_type_slug = path[0]
                    set_errors('content type does not exist', model, content_type_slug)
                  else
                    without_callbacks_and_validations(obj, model) do
                      without_extra_attributes(obj, model) do
                        do_minimal_callbacks_and_validation(obj, model)
                        if obj.errors.empty?
                          obj.save
                        else
                          set_errors(obj, model, *path)
                        end
                      end
                    end
                  end
                end
              end
            end
            self.no_errors?(model)
          end

          def should_minimally_save_model(model)
            @_models_for_minimal_save ||=
              Set.new(%w{pages content_types content_entries})
            @_models_for_minimal_save.include?(model)
          end
          alias :should_minimally_save_model? :should_minimally_save_model

          def callback_names
            @callback_names ||= ::Mongoid::Callbacks::CALLBACKS.collect do |callback|
              callback.to_s.sub(/^(before|after|around)_/, '')
            end.uniq + [ 'validate' ]
          end

          def should_skip_callback(model, callback)
            raw_filter = callback.raw_filter

            # Always validate presence and uniqueness of slug
            uniqueness_val = ::Mongoid::Validations::UniquenessValidator
            presence_val = ::Mongoid::Validations::PresenceValidator
            length_val = ::ActiveModel::Validations::LengthValidator
            if (raw_filter.kind_of?(uniqueness_val) ||
                raw_filter.kind_of?(presence_val)) \
                && (raw_filter.attributes.include?(:slug) \
                || raw_filter.attributes.include?(:_slug))
              return false
            end

            if model == 'pages'
              if (raw_filter.kind_of?(presence_val)) \
                  && raw_filter.attributes.include?(:title)
                return false
              end
            elsif model == 'content_types'
              if raw_filter.kind_of?(presence_val) \
                  && raw_filter.attributes.include?(:name)
                return false
              elsif raw_filter.kind_of?(length_val) \
                  && raw_filter.attributes.include?(:entries_custom_fields)
                return false
              end
            end

            filters_to_keep = Hash.new { |hash, key| hash[key] = [] }
            filters_to_keep.merge!({
              'pages' => %w{normalize_slug build_fullpath},
              'content_types' => %w{normalize_slug},
              'content_entries' => %w{set_slug}
            })

            filter = callback.filter
            !filters_to_keep[model].include?(filter.to_s)
          end

          def classes_for_model(model)
            [].tap do |klasses|
              if model == 'content_entries'
                content_type_klasses = self.site.content_types.collect do |ct|
                  ct.klass_with_custom_fields(:entries)
                end
              end
              klasses.push(*content_type_klasses)
              klasses.push(model_class(model))
            end
          end

          def do_minimal_callbacks_and_validation(obj, model)
            callback_names.each do |callback_name|
              classes_for_model(model).each do |klass|
                klass.send(:"_#{callback_name}_callbacks").each do |callback|
                  unless should_skip_callback(model, callback)
                    if callback.raw_filter.class == Symbol
                      obj.send(callback.raw_filter)
                    else
                      callback.raw_filter.send(:"#{callback_name}", obj)
                    end
                  end
                end
              end
            end
          end

          def without_callbacks(obj, model)
            obj.instance_eval do
              def run_callbacks(kind, *args, &block)
                if block_given?
                  yield
                else
                  true
                end
              end
            end

            yield

            obj.instance_eval do
              def run_callbacks(kind, *args, &block)
                super
              end
            end
          end
          alias :without_callbacks_and_validations :without_callbacks

          def should_keep_attribute(model, obj, attr)
            default_attributes_to_keep = %w{_id _type slug site_id}
            attributes_to_keep_for_model = Hash.new { |hash, key| hash[key] = [] }

            attributes_to_keep_for_model.merge!({
              'pages' => %w{title parent_id fullpath},
              'content_types' => %w{name},
              'content_entries' => %w{content_type_id custom_fields_recipe}
            })

            to_keep = default_attributes_to_keep + attributes_to_keep_for_model[model]

            # For content_entries, need to keep the label field
            to_keep << obj.content_type.label_field_name if model == 'content_entries'

            to_keep.include?(attr)
          end

          def removal_value(model, meth)
            case model
            when 'pages'
              return [] if meth == 'parent_ids'
            end

            nil
          end

          def remove_specific_attributes_for_model(obj, model)
            custom_fields_to_save = []
            all_custom_fields = []

            # Remove relationship fields
            if model == 'content_types'
              relationship_field_types = Set.new(%w{belings_to has_many many_to_many})
              obj.entries_custom_fields.each do |field|
                all_custom_fields << field.clone
                custom_fields_to_save << field.clone unless relationship_field_types.include?(field.type)
              end
              obj.entries_custom_fields = custom_fields_to_save
            end

            yield

            if model == 'content_types'
              obj.entries_custom_fields = all_custom_fields
            end
          end

          def without_extra_attributes(obj, model)
            attributes_removed = {}

            obj.attributes.keys.each do |attr|
              next if should_keep_attribute(model, obj, attr)

              meth = attr
              new_meth = "#{attr}_translations"
              meth = new_meth if obj.respond_to?(:"#{new_meth}")

              attributes_removed[meth] = obj.send(:"#{meth}")

              obj.send(:"#{meth}=", removal_value(model, meth))
            end

            remove_specific_attributes_for_model(obj, model) do
              yield
            end

            attributes_removed.each do |meth, val|
              obj.send(:"#{meth}=", val)
            end
          end

        end
      end
    end
  end
end
