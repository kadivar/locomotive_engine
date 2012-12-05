class Locomotive.Models.Plugin extends Backbone.Model

  initialize: ->
    plugin_config = new Locomotive.Models.PluginConfig(@get('plugin_config'))

    @set plugin_config: plugin_config

  toJSON: ->
    _.tap super, (hash) =>
      delete hash.plugin_config
      hash.plugin_config = @get('plugin_config').toJSON()
      hash.plugin_config_boolean_fields = @get('plugin_config').boolean_fields

class Locomotive.Models.PluginsCollection extends Backbone.Collection

  model: Locomotive.Models.Plugin
