Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginEntryView extends Backbone.View

  tagName: 'li'

  className: 'plugin'

  events:
    'click a.toggle': 'toggle'

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

  toggle: (event) ->
    event.stopPropagation() & event.preventDefault()
    form = @$('ol')

    if form.is(':hidden')
      @$('a.toggle').addClass('open')
      form.slideDown()
    else
      @$('a.toggle').removeClass('open')
      form.slideUp()
