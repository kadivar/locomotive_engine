
class PluginClass
  include Locomotive::Plugin

  def config_template_file
    # Rails root is at spec/dummy
    engine_root = Rails.root.join('..', '..')
    engine_root.join('spec', 'fixtures', 'assets', 'plugin_config_template.html.haml')
  end

end

Given /^I have registered the plugin "(.*)"$/ do |plugin_id|
  LocomotivePlugins.register_plugin(PluginClass, plugin_id)
end

Given /^the plugin "(.*)" is enabled$/ do |plugin_id|
  FactoryGirl.create(:enabled_plugin, :plugin_id => plugin_id, :site => @site)
end

Then /^the plugin "(.*)" should be enabled when the AJAX finishes$/ do |plugin_id|
  start_time = Time.now
  while Time.now < start_time + Capybara.default_wait_time
    enabled_plugin_ids = @site.reload.enabled_plugins.collect(&:plugin_id)
    break if enabled_plugin_ids.include?(plugin_id)
  end

  enabled_plugin_ids = @site.reload.enabled_plugins.collect(&:plugin_id)
  enabled_plugin_ids.should include(plugin_id)
end

Then /^the plugin config for "(.*)" should be:$/ do |plugin_id, table|
  plugin = @site.enabled_plugin_objects_by_id[plugin_id]
  plugin.config.should == table.rows_hash
end
