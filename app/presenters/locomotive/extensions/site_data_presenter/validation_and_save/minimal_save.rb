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
              without_callbacks_and_validations(model) do
                _all_objects(false, model) do |obj, model, *path|
                  if obj.new_record?
                    without_extra_attributes(obj, model) do
                      if obj.valid?
                        obj.save(validate: false)
                      else
                        set_errors(obj, model, *path)
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
              if (raw_filter.kind_of?(presence_val)) \
                  && raw_filter.attributes.include?(:name)
                return false
              end
            end

            filters_to_keep = Hash.new { |hash, key| hash[key] = [] }
            filters_to_keep.merge!({
              'pages' => %w{normalize_slug},
              'content_types' => %w{normalize_slug},
              'content_entries' => %w{set_slug}
            })

            filter = callback.filter
            !filters_to_keep[model].include?(filter.to_s)
          end

          def without_callbacks(model)
            callbacks = {}

            # Get all classes for this model
            klasses = []
            if model == 'content_entries'
              klasses += self.site.content_types.collect do |ct|
                ct.klass_with_custom_fields(:entries)
              end
            end
            klasses << model_class(model)

            # Skip callbacks on each klass
            klasses.each do |klass|
              # Collect the callbacks which should be skipped
              callbacks[klass] = []
              callback_names.each do |callback_name|
                klass.send(:"_#{callback_name}_callbacks").each do |callback|
                  if should_skip_callback(model, callback)
                    callbacks[klass] << callback
                  end
                end
              end
            end

            klasses.each do |klass|
              callbacks[klass].each do |callback|
                # TODO: only skip the callback for this site
                klass.skip_callback(callback.name, callback.kind,
                  callback.filter, callback.options)
              end
            end

            yield

            # Set all callbacks
            klasses.each do |klass|
              callbacks[klass].each do |callback|
                klass.set_callback(callback.name, callback.kind,
                  callback.filter, callback.options)
              end
            end
          end
          alias :without_callbacks_and_validations :without_callbacks

          def should_keep_attribute(model, obj, attr)
            default_attributes_to_keep = %w{_id _type slug site_id}
            attributes_to_keep_for_model = Hash.new { |hash, key| hash[key] = [] }

            attributes_to_keep_for_model.merge!({
              'pages' => %w{title},
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

            if model == 'content_types'
              arr = []
              obj.entries_custom_fields.each do |field|
                arr << field.clone
              end
              attributes_removed[:entries_custom_fields] = arr
              obj.entries_custom_fields = nil
            end

            yield

            if model == 'content_types'
              obj.entries_custom_fields = attributes_removed.delete(:entries_custom_fields)
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
