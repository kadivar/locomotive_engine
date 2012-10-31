module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave

        include MinimalSave

        # Do a first pass where each object is validated and saved minimally to
        # the database. Then validate and save all objects
        def insert
          first_save_ok = true
          first_save_ok = minimal_save_all

          second_save_ok = false
          if first_save_ok
            second_save_ok = self.valid?(:always_use_indices => true)
            second_save_ok &&= save_all_without_validation
          end

          save_ok = first_save_ok && second_save_ok

          cleanup! unless save_ok
          save_ok
        end

        # Validate and save each object. Do not save any objects if any
        # validation fails
        def update
          return unless self.valid?
          self.save_all_without_validation
        end

        def errors
          @errors ||= {}
        end

        protected

        # Yields object, model, *path
        def _all_objects(always_use_indices = false, *models, &block)
          models = self.models if models.blank?
          self.class.ordered_normal_models.each do |model|
            next unless models.include?(model)
            self.send(:"#{model}").each_with_index do |obj, index|
              id = (obj.new_record? || always_use_indices) ? index : obj.id
              yield obj, model, id
            end
          end
          if models.include?('content_entries')
            self.content_entries.each do |content_type_slug, entries|
              entries.each_with_index do |obj, index|
                id = (obj.new_record? || always_use_indices) ? index : obj.id
                yield obj, 'content_entries', content_type_slug, id
              end
            end
          end
        end

        def save_all_without_validation
          result = true
          _all_objects do |obj|
            result = presenter_for(obj).save(validate: false) && result
          end
          result
        end

        def valid?(options = {})
          self.errors.clear
          _all_objects(options[:always_use_indices]) do |obj, model, *path|
            if model == 'content_entries' && !obj.content_type
              content_type_slug, index = *path
              set_errors('content type does not exist', model, content_type_slug)
            else
              presenter = presenter_for(obj)
              unless presenter.valid?
                set_errors(presenter, model, *path)
              end
            end
          end
          self.errors.empty?
        end

        def cleanup!
          _all_objects do |obj|
            obj.destroy
          end
        end

        def set_errors(model_or_string, *path)
          is_string = model_or_string.kind_of?(String)

          # Build path
          current_container = self.errors
          current_element = nil
          path.each_with_index do |element, index|
            current_element = element
            unless index == path.length - 1
              current_container[element] ||= {}
              current_container = current_container[element]
            end
          end

          # Add error messages
          if is_string
            current_container[current_element] = [model_or_string]
          else
            current_container[current_element] = model_or_string.errors.messages
          end
        end

      end
    end
  end
end
