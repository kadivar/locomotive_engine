# coding: utf-8

require 'spec_helper'

module Locomotive
  describe PluginData do

    before(:each) do
      @plugin_data = FactoryGirl.create(:plugin_data,
        :plugin_id => MyPlugin.default_plugin_id)
    end

    it 'should supply the plugin class' do
      @plugin_data.plugin_class.should == MyPlugin
    end

  end
end
