module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave

        include ContentTypes
        include ContentEntries
        include MinimalSave

        attr_reader :errors

        def save(two_phase = false)
          first_save_ok = true
          if two_phase
            first_save_ok = minimal_save_all
          end

          puts 'Did minimal save!'
          puts "Went ok? #{first_save_ok}"
          puts "Pages: #{self.site.pages.all.to_ary}"

          if first_save_ok && self.valid?
            save_all

            puts 'Did full save!'
            puts "Pages: #{self.site.pages.all.to_ary}"

            true
          else
            cleanup
            false
          end
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

        def save_all
          _all_objects do |obj|
            presenter_for(obj).save
          end
        end

        def valid?
          all_valid = true
          _all_objects do |obj, model, *path|
            puts "Saving page: #{obj}" if model == 'pages'
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
          end
          all_valid
        end

        def cleanup
          _all_objects do |obj|
            obj.destroy
          end
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

      end
    end
  end
end
