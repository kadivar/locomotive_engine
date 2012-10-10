module Locomotive
  module Extensions
    module SiteDataPresenter
      module Authorization

        # Authorize action with loaded data
        def authorize!(ability, action)
          messages = []
          failed = false

          self.models.each do |model|
            begin
              ability.authorize!(action, model_class(model))
            rescue CanCan::AccessDenied => e
              failed = true
              messages << e.message
            end
          end

          if failed
            raise CanCan::AccessDenied.new(messages)
          end
        end

        protected

        # Get the class for a model
        def model_class(model)
          "Locomotive::#{model.singularize.camelize}".constantize
        end

      end
    end
  end
end
