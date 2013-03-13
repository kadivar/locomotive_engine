
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

Given /^the plugin data for "(.*?)" has ID "(.*?)"$/ do |plugin_id, id|
  plugin_data = @site.reload.all_plugin_data.where(plugin_id: plugin_id).first

  if plugin_data
    new_plugin_data = @site.plugin_data.new
    new_plugin_data.id = BSON::ObjectId(id)

    %w{plugin_id config enabled}.each do |meth|
      new_plugin_data.send("#{meth}=", plugin_data.send(meth))
    end

    plugin_data.destroy
    new_plugin_data.save!
  end
end

Given /^the config for the plugin "(.*?)" is:$/ do |plugin_id, table|
  plugin_data = @site.reload.plugin_data.detect do |plugin_data|
    plugin_data.plugin_id == plugin_id
  end

  if plugin_data
    plugin_data.config = table.rows_hash
    @site.save!
  else
    FactoryGirl.create(:plugin_data,
                       :plugin_id => plugin_id,
                       :config => table.rows_hash,
                       :site => @site)
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
