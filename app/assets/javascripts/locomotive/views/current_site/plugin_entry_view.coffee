Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginEntryView extends Backbone.View

  tagName: 'li'

  className: 'plugin'

  render: ->
    $(@el).html(ich.plugin_entry(@model.toJSON()))

    return @
