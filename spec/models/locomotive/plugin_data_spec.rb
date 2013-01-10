# coding: utf-8

require 'spec_helper'

module Locomotive
  describe PluginData do

    before(:each) do
      Locomotive::Plugins::SpecHelpers.before_each(__FILE__)
      @plugin_data = FactoryGirl.create(:plugin_data,
        :plugin_id => MyPlugin.default_plugin_id)
    end

    it 'should supply the plugin class' do
      @plugin_data.plugin_class.should == MyPlugin
    end

    protected

    Locomotive::Plugins::SpecHelpers.define_plugins(__FILE__) do
      class MyPlugin
        include Locomotive::Plugin
      end
    end

  end
end
