
class PluginClass
  include Locomotive::Plugin

  def config_template_file
    Rails.root.join('spec', 'fixtures', 'assets', 'plugin_config_template.html.haml')
  end

end

Given /^I have registered the plugin "([^"]*)"$/ do |plugin_id|
  LocomotivePlugins.register_plugin(PluginClass, plugin_id)
end

Given /^the plugin "(.*?)" is enabled$/ do |plugin_id|
  FactoryGirl.create(:enabled_plugin, :plugin_id => plugin_id)
end

Then /^the plugin "(.*?)" should be enabled$/ do |plugin_id|
  enabled_plugin_ids = @site.reload.enabled_plugins.collect(&:plugin_id)
  enabled_plugin_ids.count.should == 1
  enabled_plugin_ids.should include(plugin_id)
end
