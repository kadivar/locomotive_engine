module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        module MinimalSave

          protected

          def models_for_minimal_save
            %w{pages content_types content_entries}
          end

          def minimal_save_all
            all_valid = true
            without_callbacks_and_validations do
              _all_objects do |obj, model, *path|
                if models_for_minimal_save.include?(model)
                  without_extra_attributes(obj, model) do
                    # TODO: validating...not DRY
                    #if model == 'content_entries' && !obj.content_type
                      #content_type_slug, index = *path
                      #all_valid = false
                      #set_errors('content type does not exist', model, content_type_slug)
                    #else
                      if obj.valid?
                        all_valid = obj.save && all_valid
                      else
                        all_valid = false
                        set_errors(obj, model, *path)
                      end
                    #end
                  end
                end
              end
            end
            all_valid
          end

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
                && raw_filter.attributes.include?(:slug)
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

          def without_callbacks
            callbacks = {}

            # Skip all callbacks
            self.models_for_minimal_save.each do |model|
              klass = model_class(model)

              callbacks[model] = []
              callback_names.each do |callback_name|
                klass.send(:"_#{callback_name}_callbacks").each do |callback|
                  if should_skip_callback(model, callback)
                    callbacks[model] << callback
                  end
                end
              end
              callbacks[model].each do |callback|
                # TODO: only skip the callback for this site
                klass.skip_callback(callback.name, callback.kind,
                  callback.filter, callback.options)
              end
            end

            yield

            # Set all callbacks
            self.models_for_minimal_save.each do |model|
              klass = model_class(model)
              callbacks[model].each do |callback|
                klass.set_callback(callback.name, callback.kind,
                  callback.filter, callback.options)
              end
            end
          end
          alias :without_callbacks_and_validations :without_callbacks

          def attributes_to_keep(model)
            default_attributes_to_keep = %w{_id _type slug site_id}
            attributes_to_keep_for_model = Hash.new { |hash, key| hash[key] = [] }

            attributes_to_keep_for_model.merge!({
              'pages' => %w{title},
              'content_types' => %w{name},
              'content_entries' => %w{name content_type_id custom_fields_recipe}
            })

            default_attributes_to_keep + attributes_to_keep_for_model[model]
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
              next if attributes_to_keep(model).include?(attr)

              meth = attr
              new_meth = "#{attr}_translations"
              meth = new_meth if obj.respond_to?(:"#{new_meth}")

              attributes_removed[meth] = obj.send(:"#{meth}")
              obj.send(:"#{meth}=", removal_value(model, meth))
            end

            yield

            attributes_removed.each do |meth, val|
              obj.send(:"#{meth}=", val)
            end
          end

        end
      end
    end
  end
end
