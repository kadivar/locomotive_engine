module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        module ContentEntries

          protected

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
end
