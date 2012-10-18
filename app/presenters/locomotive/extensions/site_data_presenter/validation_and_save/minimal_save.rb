module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        module MinimalSave

          protected

          def minimal_save_all
            all_valid = true
            without_callbacks_and_validations do
              _all_objects do |obj, model, *path|
                without_extra_attributes(obj, model) do
                  # TODO: validating...not DRY
                  if model == 'content_entries' && !obj.content_type
                    content_type_slug, index = *path
                    all_valid = false
                    set_errors('content type does not exist', model, content_type_slug)
                  else
                    if obj.valid?
                      all_valid = obj.save && all_valid
                    else
                      all_valid = false
                      set_errors(obj, model, *path)
                    end
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
            if model == 'pages'
              filter = callback.filter
              raw_filter = callback.raw_filter
              if raw_filter.kind_of?(::Mongoid::Validations::UniquenessValidator) && raw_filter.attributes.include?(:slug)
                false
              else
                filters_to_keep = %w{normalize_slug}.map { |f| f.to_sym }
                !filters_to_keep.include?(filter)
              end
            else
              true
            end
          end

          def without_callbacks
            callbacks = {}

            # Skip all callbacks
            self.models.each do |model|
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
            self.models.each do |model|
              klass = model_class(model)
              callbacks[model].each do |callback|
                klass.set_callback(callback.name, callback.kind,
                  callback.filter, callback.options)
              end
            end
          end
          alias :without_callbacks_and_validations :without_callbacks

          def without_extra_attributes(obj, model)
            attributes_removed = {}
            if model == 'pages'
              attributes_to_keep = %w{_id slug title site_id}
              obj.attributes.keys.each do |attr|
                next if attributes_to_keep.include?(attr)

                meth = attr
                new_meth = "#{attr}_translations"
                meth = new_meth if obj.respond_to?(:"#{new_meth}")

                attributes_removed[meth] = obj.send(:"#{meth}")
                if attr == 'parent_ids'
                  obj.send(:"#{meth}=", [])
                else
                  obj.send(:"#{meth}=", nil)
                end
              end
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
