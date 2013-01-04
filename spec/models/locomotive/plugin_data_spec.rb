# coding: utf-8

require 'spec_helper'

module Locomotive
  describe PluginData do

    before(:each) do
      Locomotive::Plugins::SpecHelpers.stub_registered_plugins(MyPlugin)
      @plugin_data = FactoryGirl.create(:plugin_data,
        :plugin_id => MyPlugin.default_plugin_id)
    end

    it 'should supply the plugin class' do
      @plugin_data.plugin_class.should == MyPlugin
    end

    protected

    Locomotive::Plugins.init_plugins do
      class MyPlugin
        include Locomotive::Plugin
      end
    end

  end
end
