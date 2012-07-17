module Locomotive
  module Extensions
    module Site
      module Plugins

        extend ActiveSupport::Concern

        included do

          field :enabled_plugins, :type => Array, :default => []

        end

      end
    end
  end
end
