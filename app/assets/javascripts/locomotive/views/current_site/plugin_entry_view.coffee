Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginEntryView extends Backbone.View

  tagName: 'li'

  className: 'plugin'

  render: ->
    $(@el).html(ich.plugin_entry(@model.toJSON()))

    @render_config_view()

    Backbone.ModelBinding.bind @, all: 'class'

    return @

  render_config_view: ->
    @config_view = new Locomotive.Views.CurrentSite.PluginConfigView
      plugin_id: @model.get('plugin_id')
      model: @model.get('plugin_config')
    @$('span.actions').before(@config_view.render().el)
