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
    plugins = @model.get('plugins')
    if plugins.length != 0
      @$('> .empty').hide()
      @$('> ul').show()
      plugins.each (plugin) =>
        @_insert_entry(plugin)

  _insert_entry: (plugin) ->
    view = new Locomotive.Views.CurrentSite.PluginEntryView model: plugin

    (@_entry_views ||= []).push(view)

    @$('ul').append(view.render().el)
