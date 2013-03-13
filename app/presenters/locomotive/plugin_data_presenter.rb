module Locomotive
  class PluginDataPresenter < BasePresenter

    properties :name, :plugin_id, only_getter: true
    property :enabled, type: 'Boolean'
    property :config

  end
end
