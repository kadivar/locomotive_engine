Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.EnabledPluginsView extends Backbone.View

  tagName: 'div'

  className: 'list'

  render: ->
    $(@el).html(ich.enabled_plugins_list(@model.toJSON()))

    @render_plugins()

    return @

  render_plugins: ->
    if @model.get('enabled_plugins').length != 0
      @$('> .empty').hide()
      @$('> ul').show()
      @model.get('enabled_plugins').each (enabled_plugin) =>
        @_insert_entry(enabled_plugin)

  _insert_entry: (enabled_plugin) ->
    view = new Locomotive.Views.CurrentSite.EnabledPluginEntryView model: enabled_plugin

    (@_entry_views ||= []).push(view)

    @$('> ul').append(view.render().el)
