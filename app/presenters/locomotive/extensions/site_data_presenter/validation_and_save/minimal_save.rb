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
                    unless obj.valid?
                      all_valid = false
                      set_errors(obj, model, *path)
                    end
                  end
                  obj.save
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

          def without_callbacks
            callbacks = {}

            # Skip all callbacks
            self.models.each do |model|
              klass = model_class(model)

              callbacks[model] = []
              callback_names.each do |callback_name|
                callbacks[model] += klass.send(:"_#{callback_name}_callbacks")
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
            yield
          end

        end
      end
    end
  end
end
