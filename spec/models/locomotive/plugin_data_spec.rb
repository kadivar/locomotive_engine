# coding: utf-8

require 'spec_helper'

module Locomotive
  describe PluginData do

    before(:each) do
      LocomotivePlugins.register_plugin(MyPlugin)
      plugin_id = LocomotivePlugins.default_id(MyPlugin)
      @plugin_data = FactoryGirl.create(:plugin_data,
                                           :plugin_id => plugin_id)
    end

    it 'should supply the plugin class' do
      @plugin_data.plugin_class.should == MyPlugin
    end

    protected

    class MyPlugin
      include Locomotive::Plugin
    end

  end
end
