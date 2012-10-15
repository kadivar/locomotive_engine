module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        module ContentTypes

          protected

          ## Validate and save ##

          # Validate content_types. Return false and add errors if invalid.
          # This will leave the content_types saved for the first stage in the
          # database
          def validate_content_types
            valid = true
            unless content_type_first_stage_done
              valid = save_content_types_first_stage
            end
            valid &&= validate_content_type_slugs
            if valid
              self.content_types.each do |ct|
                presenter_for(ct).set_field_class_names
              end
            end
            valid &&= default_validate_model('content_types')
          end

          # Save all content_types
          def save_content_types
            unless content_type_first_stage_done
              save_content_types_first_stage
            end
            default_save_model('content_types')
            content_type_first_stage_done = false
          end


          ## Cleanup ##

          # Array of content_type objects which have been saved and need to be
          # destroyed on cleanup
          def content_type_objects_to_destroy
            @content_type_objects_to_destroy ||= []
          end

          # Add a content_type object to be destroyed on cleanup
          def add_content_type_object_to_destroy(content_type)
            content_type_objects_to_destroy << content_type
          end

          # Clear the list of content_type objects to be destroyed on cleanup
          def reset_content_type_objects_to_destroy
            @content_type_objects_to_destroy = []
          end

          # Destroy all content_type objects which have been saved in the first
          # stage. Reset the list of content_type objects to be destroyed
          def cleanup_content_types
            content_type_objects_to_destroy.each do |obj|
              obj.destroy unless obj.new_record?
            end
            reset_content_type_objects_to_destroy
            content_type_first_stage_done = false
          end


          ## First stage of save ##

          # Specifies whether the first stage of saving is complete
          attr_accessor :content_type_first_stage_done

          # Do the first stage of saving content_types. We need this so that
          # relationship fields can be linked together correctly in the second
          # stage
          def save_content_types_first_stage
            # FIXME: do this is one loop
            fields = {}
            field_content_type_slugs = {}
            self.content_types.each do |ct|
              fields[ct] = remove_relationship_fields(ct)
              field_content_type_slugs[ct] = remove_field_content_type_slugs(ct)
            end
            valid = default_validate_model('content_types')
            if valid
              default_save_model('content_types')
            end
            self.content_types.each do |ct|
              add_relationship_fields(ct, fields[ct])
              add_field_content_type_slugs(ct, field_content_type_slugs[ct])
            end
            content_type_first_stage_done = true
            self.content_types.each { |ct| add_content_type_object_to_destroy(ct) }
            valid
          end


          ## Remove relationship field info ##

          # Field types which are relationships between content_types
          def relationship_field_types
            %w{belongs_to has_many many_to_many}
          end

          # Check if field type is a relationship field
          def is_relationship_field(type)
            relationship_field_types.include?(type)
          end

          # Add relationship fields to the content_type. This should be used to
          # re-add the fields which were removed with
          # remove_relationship_fields
          def add_relationship_fields(content_type, fields)
            content_type.entries_custom_fields += fields
          end

          # Remove all relationship fields from a content type. This is done so
          # that the first stage of the save will complete successfully without
          # trying to link the content types with relationships. Returns the
          # fields which were removed
          def remove_relationship_fields(content_type)
            [].tap do |fields|
              content_type.entries_custom_fields.reject! do |field|
                if relationship_field_types.include?(field.type)
                  fields << field
                end
              end
            end
          end

          # Add content_type_slugs to the presenter for a content_type. This
          # should be used to re-add the content_type_slugs which were removed
          # with remove_field_content_type_slugs
          def add_field_content_type_slugs(content_type, field_content_type_slugs)
            presenter_for(content_type).field_content_type_slugs =
              field_content_type_slugs
          end

          # Remove all content_type_slugs from the presenter for a
          # content_type. This is done so that the first stage of the save will
          # complete successfully without trying to link content types with
          # relationships
          def remove_field_content_type_slugs(content_type)
            content_type_slugs =
              presenter_for(content_type).field_content_type_slugs
            presenter_for(content_type).field_content_type_slugs = {}
            content_type_slugs
          end


          ## Custom validation ##

          # Validate the content_type_slugs for each content_type. These slugs
          # should match a content_type which is in the database. This
          # validation should run after the first stage of saving
          def validate_content_type_slugs
            all_valid = true

            # Assume first stage of save is done
            slugs = self.site.content_types.collect(&:slug)
            self.content_types.each_with_index do |ct, content_type_index|
              # Iterate through fields and see if there's a content_type_slug
              presenter = presenter_for(ct)
              ct.entries_custom_fields.each_with_index do |field, field_index|
                content_type_slug = presenter.field_content_type_slugs[field]
                if content_type_slug
                  # If the slug doesn't match any content_types, add errors
                  unless slugs.include?(content_type_slug)
                    all_valid = false
                    set_errors('invalid content_type_slug', 'content_types',
                      content_type_index, 'entries_custom_fields', field_index)
                  end
                end
              end
            end

            all_valid
          end

        end
      end
    end
  end
end
