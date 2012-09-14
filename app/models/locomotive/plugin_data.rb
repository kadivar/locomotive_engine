module Locomotive
  class PluginData

    include Locomotive::Mongoid::Document

    ## fields ##
    field :plugin_id
    field :config, :type => Hash, :default => {}
    field :enabled, :default => false

    ## validations ##

    validates_presence_of :plugin_id
    validates_uniqueness_of :plugin_id

    ## relationships ##

    embedded_in :site, :class_name => 'Locomotive::Site'

    ## methods ##

    def self.plugin_name(plugin_id)
      plugin_id.humanize
    end

    def name
      self.class.plugin_name(self.plugin_id)
    end

    def plugin_class
      LocomotivePlugins.registered_plugins[self.plugin_id]
    end

    def to_presenter(options)
      Locomotive::EnabledPluginPresenter.new(self, options)
    end

    def as_json(options = {})
      self.to_presenter(options).as_json
    end

  end
end
