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
      Locomotive::Plugins.registered_plugins[self.plugin_id]
    end

    def to_presenter(options)
      Locomotive::PluginDataPresenter.new(self, options)
    end

    def as_json(options = {})
      self.to_presenter(options).as_json
    end

    def construct_plugin_object
      if plugin_class
        plugin_class.new.tap do |plugin_object|
          %w{config mountpoint}.each do |meth|
            plugin_object.public_send(:"#{meth}=", self.send(meth))
          end
        end
      else
        raise %{Expected plugin_class to not be nil. Is plugin '#{plugin_id}' registered?}
      end
    end

    protected

    def mountpoint
      Plugins::Mounter.mountpoint_for_plugin_id(plugin_id)
    end

  end
end
