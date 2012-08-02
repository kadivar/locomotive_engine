module Locomotive
  module Extensions
    module Site
      module Plugins

        extend ActiveSupport::Concern

        included do

          embeds_many :enabled_plugins, :class_name => 'Locomotive::EnabledPlugin'
          accepts_nested_attributes_for :enabled_plugins

        end

      end
    end
  end
end
