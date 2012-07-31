module Locomotive
  module Extensions
    module Site
      module Plugins

        extend ActiveSupport::Concern

        included do

          embeds_many :enabled_plugins

        end

      end
    end
  end
end
