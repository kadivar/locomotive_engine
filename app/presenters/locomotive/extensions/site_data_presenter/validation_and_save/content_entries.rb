module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        module ContentEntries

          protected

          def save_content_entries
            # Save without relationship fields
            self.content_entries.each do |_, entries|
              entries.each { |obj| presenter_for(obj).save(false) }
            end

            # Save normally
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


          ## Cleanup ##

          # TODO: duplicated in content_types. DRY it up!

          # Array of content_entry objects which have been saved and need to be
          # destroyed on cleanup
          def content_entry_objects_to_destroy
            @content_entry_objects_to_destroy ||= []
          end

          # Add a content_entry object to be destroyed on cleanup
          def add_content_entry_object_to_destroy(content_entry)
            content_entry_objects_to_destroy << content_entry
          end

          # Clear the list of content_entry objects to be destroyed on cleanup
          def reset_content_entry_objects_to_destroy
            @content_entry_objects_to_destroy = []
          end

          # Destroy all content_entry objects which have been saved in the
          # first stage. Reset the list of content_entry objects to be
          # destroyed
          def cleanup_content_entries
            content_entry_objects_to_destroy.each do |obj|
              obj.destroy unless obj.new_record?
            end
            reset_content_entry_objects_to_destroy
            content_entry_first_stage_done = false
          end


          ## First stage of save ##

          # TODO

        end
      end
    end
  end
end
