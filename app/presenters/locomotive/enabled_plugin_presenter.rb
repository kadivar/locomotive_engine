module Locomotive
  class EnabledPluginPresenter < BasePresenter

    delegate :name, :plugin_id, :config, :plugin_class, :to => :source

    def included_methods
      super + %w(name plugin_id config plugin_class)
    end

  end
end
