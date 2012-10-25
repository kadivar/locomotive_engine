module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave

        include MinimalSave

        def save(options = {})
          options = {
            :two_phase => false
          }.merge(options)

          first_save_ok = true
          if options[:two_phase]
            first_save_ok = minimal_save_all
          end

          second_save_ok = false
          if first_save_ok
            second_save_ok = self.valid? && save_all_without_validation
          end

          save_ok = first_save_ok && second_save_ok

          cleanup unless save_ok
          save_ok
        end

        def errors
          @errors ||= {}
        end

        protected

        # Yields object, model, *path
        def _all_objects(&block)
          self.class.ordered_normal_models.each do |model|
            self.send(:"#{model}").each_with_index do |obj, index|
              id = obj.new_record? && index || obj.id
              yield obj, model, id
            end
          end
          self.content_entries.each do |content_type_slug, entries|
            entries.each_with_index do |obj, index|
              id = obj.new_record? && index || obj.id
              yield obj, 'content_entries', content_type_slug, id
            end
          end
        end

        def save_all_without_validation
          _all_objects do |obj|
            presenter_for(obj).save(validate: false)
          end
          self.errors.empty?
        end

        def valid?
          self.errors.clear
          _all_objects do |obj, model, *path|
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

        def cleanup
          _all_objects do |obj|
            obj.destroy
          end
        end

        def set_errors(model_or_string, *path)
          is_string = model_or_string.kind_of?(String)

          # Build path
          current_container = @errors
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
