# coding: utf-8

require 'spec_helper'

describe Locomotive::EnabledPlugin do

  before(:each) do
    LocomotivePlugins.register_plugin(MyPlugin)
    plugin_id = LocomotivePlugins.default_id(MyPlugin)
    @enabled_plugin = FactoryGirl.create(:enabled_plugin,
                                         :plugin_id => plugin_id)
  end

  it 'should supply the plugin class' do
    @enabled_plugin.plugin_class.should == MyPlugin
  end

  protected

  class MyPlugin
    include Locomotive::Plugin
  end

end
