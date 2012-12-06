
class PluginClass
  include Locomotive::Plugin

  attr_accessor :greeting
  def http_prefix ; 'http://' ; end
  def surround_with_paragraph(str) ; "<p>#{str}</p>" ; end

  class Drop < ::Liquid::Drop
    def greeting
      @context.registers[:plugin_object].greeting
    end
  end

  module Filters
    def add_http_prefix(input)
      prefix = @context.registers[:plugin_object].http_prefix
      if input.start_with?(prefix)
        input
      else
        "#{prefix}#{input}"
      end
    end
  end

  class Paragraph < ::Liquid::Block
    def render(context)
      obj = @context.register[:plugin_object]
      obj.surround_with_paragraph(render_all(@nodelist, context))
    end

    def render_disabled(context)
      render_all(@nodelist, context)
    end
  end

  class Newline < ::Liquid::Tag
    def render(context)
      "<br />"
    end
  end

  before_filter :set_greeting

  def to_liquid
    @drop ||= Drop.new
  end
  alias :drop :to_liquid

  def config_template_file
    # Rails root is at spec/dummy
    engine_root = Rails.root.join('..', '..')
    engine_root.join('spec', 'fixtures', 'assets', 'plugin_config_template.html.haml')
  end

  def self.liquid_filters
    Filters
  end

  def self.liquid_tags
    {
      :paragraph => Paragraph,
      :newline => Newline
    }
  end

  def set_greeting
    self.greeting = 'Hello, World!'
  end

end

Given /^I have registered the plugin "(.*)"$/ do |plugin_id|
  LocomotivePlugins.register_plugin(PluginClass, plugin_id)
  Locomotive::Plugins::LiquidTagLoader.load
end

Given /^the plugin "(.*)" is enabled$/ do |plugin_id|
  plugin_data = @site.reload.plugin_data.detect do |plugin_data|
    plugin_data.plugin_id == plugin_id
  end

  if plugin_data
    plugin_data.enabled = true
    @site.save!
  else
    FactoryGirl.create(:plugin_data,
                       :plugin_id => plugin_id,
                       :enabled => true,
                       :site => @site)
  end
end

Given /^the plugin "(.*)" is disabled$/ do |plugin_id|
  plugin_data = @site.reload.plugin_data.detect do |plugin_data|
    plugin_data.plugin_id == plugin_id
  end

  if plugin_data
    plugin_data.enabled = false
    @site.save!
  end
end

When /^I clear all registered plugins$/ do
  LocomotivePlugins.clear_registered_plugins
end

Then /^the plugin "(.*)" should be enabled$/ do |plugin_id|
  enabled_plugin_ids = @site.reload.plugin_data.select do |plugin_data|
    plugin_data.enabled
  end.collect(&:plugin_id)
  enabled_plugin_ids.should include(plugin_id)
end

Then /^the plugin config for "(.*)" should be:$/ do |plugin_id, table|
  @site.reload

  # Force site to recreate plugin objects
  @site.instance_variable_set(:@all_plugin_objects_by_id, nil)
  @site.instance_variable_set(:@enabled_plugin_objects_by_id, nil)
  @site.instance_variable_set(:@plugin_data_by_id, nil)

  plugin = @site.all_plugin_objects_by_id[plugin_id]
  plugin.config.should == table.rows_hash
end
