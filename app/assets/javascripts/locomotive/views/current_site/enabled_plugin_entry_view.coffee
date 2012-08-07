Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.EnabledPluginEntryView extends Backbone.View

  tagName: 'li'

  className: 'enabled_plugin'

  render: ->
    console.log ich.enabled_plugin_entry(@model.toJSON())
    $(@el).html(ich.enabled_plugin_entry(@model.toJSON()))

    return @
