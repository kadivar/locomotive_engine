module Locomotive
  module Extensions
    module SiteDataPresenter
      module Validation

        attr_reader :errors

        def valid?
          all_valid = true
          self.class.ordered_normal_models.each do |model|
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

        protected

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

      end
    end
  end
end
