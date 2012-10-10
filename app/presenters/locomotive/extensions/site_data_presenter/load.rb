module Locomotive
  module Extensions
    module SiteDataPresenter
      module Load

        ## Load the data for each model ##

        def load_data(ids = :all)
          self.models.each do |model|
            if ids == :all
              data = load_model(model, ids)
            else
              data = load_model(model, ids[model])
            end
            @data[model] = data
          end
        end

        protected

        def load_model(model, ids)
          meth = :"load_#{model}"
          if self.respond_to?(meth)
            self.send(meth, ids)
          else
            if ids == :all
              site.send(model)
            else
              site.send(model).find(ids)
            end
          end
        end

        def load_content_entries(ids)
          ids ||= {}
          site.content_types.inject({}) do |h, content_type|
            content_type_slug = content_type.slug
            if ids == :all || ids[content_type_slug] == :all
              entries = content_type.entries
            else
              if ids[content_type_slug]
                entries = content_type.entries.find(ids[content_type_slug])
              end
            end
            h[content_type_slug] = entries if entries
            h
          end
        end

      end
    end
  end
end
