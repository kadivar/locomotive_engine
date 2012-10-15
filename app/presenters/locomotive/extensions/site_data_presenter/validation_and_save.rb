module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave

        include ContentTypes

        attr_reader :errors

        def save
          if self.valid?(false)
            self.class.ordered_models.each do |model|
              self.save_model(model)
            end
            true
          else
            false
          end
        end

        protected

        # Check to see if all objects are valid. If cleanup is false, then
        # if everything validates successfully, leave any objects in the
        # database which have been created. If cleanup is false, or if the
        # validations return false, all objects created in the database should
        # be destroyed before returning
        def valid?(cleanup = true)
          all_valid = true
          self.class.ordered_models.each do |model|
            all_valid = validate_model(model) && all_valid
          end
          unless all_valid && !cleanup
            self.class.ordered_models.each do |model|
              cleanup_model(model)
            end
          end
          all_valid
        end

        def set_errors(model_or_string, *path)
          @errors ||= {}
          @errors['errors'] ||= {}

          is_string = model_or_string.kind_of?(String)

          # Build path
          current_container = @errors['errors']
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

        def save_model(model)
          meth = :"save_#{model}"
          if self.respond_to?(meth)
            self.send(meth)
          else
            default_save_model(model)
          end
        end

        def default_save_model(model)
          self.send(:"#{model}").each { |obj| save_object(obj) }
        end

        def save_object(obj)
          presenter_for(obj).save
        end

        def validate_model(model)
          meth = :"validate_#{model}"
          if self.respond_to?(meth)
            self.send(meth)
          else
            default_validate_model(model)
          end
        end

        def default_validate_model(model)
          valid = true
          objects = self.send(:"#{model}")
          objects.each_with_index do |obj, index|
            unless obj.valid?
              valid = false
              id = obj.new_record? && index || obj.id
              set_errors(obj, model, id)
            end
          end
          valid
        end

        def cleanup_model(model)
          meth = :"cleanup_#{model}"
          if self.respond_to?(meth)
            self.send(meth)
          end
        end

        ## Content Entries ##

        def save_content_entries
          self.content_entries.each do |_, entries|
            entries.each { |obj| presenter_for(obj).save }
          end
        end

        def validate_content_entries
          all_valid = true
          self.content_entries.each do |content_type_slug, entries|
            entries.each_with_index do |obj, index|
              if obj.content_type
                unless obj.valid?
                  all_valid = false
                  id = obj.new_record? && index || obj.id
                  set_errors(obj, 'content_entries', content_type_slug, id)
                end
              else
                all_valid = false
                set_errors('content type does not exist', 'content_entries',
                  content_type_slug)
              end
            end
          end
          all_valid
        end

      end
    end
  end
end
