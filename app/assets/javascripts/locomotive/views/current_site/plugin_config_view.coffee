Locomotive.Views.CurrentSite ||= {}

class Locomotive.Views.CurrentSite.PluginConfigView extends Backbone.View

  tagName: 'ol'

  className: 'nested'

  attributes:
    style: 'display: none;'

  initialize: ->
    @_get_config_view_render_function()

  render: ->
    if (@has_config_view())
      $(@el).html(@render_config_view({ content_types: Locomotive.content_types }))
      @model.boolean_fields = @_boolean_fields()

    Backbone.ModelBinding.bind @, all: 'name'

    return @

  has_config_view: ->
    return (@render_config_view != undefined)

  _boolean_fields: ->
    checkboxes = $(@el).find('input[type=checkbox]')
    _.map checkboxes, (checkbox) ->
      $(checkbox).attr('name')

  _get_config_view_render_function: ->
    config_view_id = "#{@options.plugin_id}_config_view"
    @render_config_view = ich.templates[config_view_id]
