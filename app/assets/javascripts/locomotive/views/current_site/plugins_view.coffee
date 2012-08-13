Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginsView extends Backbone.View

  tagName: 'div'

  className: 'list'

  initialize: ->
    Backbone.ModelBinding.bind @, checkbox: 'class'

  render: ->
    $(@el).html(ich.plugins_list(@model.toJSON()))

    @render_plugins()

    return @

  render_plugins: ->
    available_plugins = @model.get('available_plugins')
    if available_plugins.length != 0
      @$('> .empty').hide()
      @$('> ul').show()
      _.each available_plugins, (available_plugin) =>
        @_insert_entry(available_plugin)

  _insert_entry: (plugin) ->
    @$('> ul').append(ich.plugin_entry(plugin))
