
class PluginClass
  include Locomotive::Plugin
end

Given /^I have registered the plugin "([^"]*)"$/ do |plugin_id|
  LocomotivePlugins.register_plugin(PluginClass, plugin_id)
end

Then /^the plugin "(.*?)" should be enabled$/ do |plugin_id|
  enabled_plugin_ids = @site.reload.enabled_plugins.collect(&:plugin_id)
  enabled_plugin_ids.count.should == 1
  enabled_plugin_ids.should include(plugin_id)
end
