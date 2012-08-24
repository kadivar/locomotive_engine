Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginEntryView extends Backbone.View

  tagName: 'li'

  className: 'plugin'

  render: ->
    $(@el).html(ich.plugin_entry(@model.toJSON()))

    # Get plugin config view
    config_view_id = "#{@model.plugin_id}_config_view"
    render_config_view = ich.templates[config_view_id]
    if (render_config_view)
      $(@el).children('ol.nested').html(render_config_view())

    Backbone.ModelBinding.bind @, all: 'class'

    return @
