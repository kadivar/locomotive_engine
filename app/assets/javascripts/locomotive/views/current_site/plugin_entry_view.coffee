Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginEntryView extends Backbone.View

  tagName: 'li'

  className: 'plugin'

  events:
    'click a.toggle': 'toggle'

  render: ->
    $(@el).html(ich.plugin_entry(@model.toJSON()))

    Backbone.ModelBinding.bind @, all: 'class'

    @set_id()

    @render_config_view()

    @hide_toggle_unless_config_view()

    return @

  set_id: ->
    id = "plugin_entry_#{@model.get('plugin_id')}"
    $(@el).attr('id', id)

  render_config_view: ->
    @config_view = new Locomotive.Views.CurrentSite.PluginConfigView
      plugin_id: @model.get('plugin_id')
      model: @model.get('plugin_config')
    @$('span.actions').before(@config_view.render().el)

  hide_toggle_unless_config_view: ->
    if !@config_view.has_config_view()
      @$('a.toggle').hide()

  toggle: (event) ->
    event.stopPropagation() & event.preventDefault()
    form = @$('ol')

    if form.is(':hidden')
      @$('a.toggle').addClass('open')
      form.slideDown()
    else
      @$('a.toggle').removeClass('open')
      form.slideUp()
