Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginConfigView extends Backbone.View

  tagName: 'ol'

  className: 'nested'

  attributes:
    style: 'display: none;'

  render: ->
    config_view_id = "#{@options.plugin_id}_config_view"
    render_config_view = ich.templates[config_view_id]
    if (render_config_view)
      $(@el).html(render_config_view())

    Backbone.ModelBinding.bind @, all: 'name'

    return @
