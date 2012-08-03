
class PluginClass
  include Locomotive::Plugin
end

Given /^I have registered the plugin "([^"]*)"$/ do |plugin_id|
  LocomotivePlugins.register_plugin(PluginClass, plugin_id)
end

Then /^I should be able to add the plugin "([^"]*)" to my site$/ do |plugin_id|
  visit edit_current_site_path

  check "site_enabled_plugins_#{plugin_id}"
  click_button 'Save'

  enabled_plugin_ids = @site.reload.enabled_plugins.collect(&:plugin_id)
  enabled_plugin_ids.count.should == 1
  enabled_plugin_ids.should include(plugin_id)
end
