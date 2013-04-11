
require 'spec_helper'

module Locomotive
  describe Plugins do

    it 'should register loaded plugins' do
      Plugins.expects(:register_plugin!)
      Plugins.init_plugins do
        load_plugin 'my_plugin.rb', true
      end
    end

    it 'should require all plugins from Bundler' do
      Bundler.expects(:require).with(:locomotive_plugins)
      Plugins.bundler_require
    end

    it 'should call init_plugins when requiring from Bundler' do
      Plugins.expects(:init_plugins)
      Plugins.bundler_require
    end

    it 'should allow for multiple init blocks' do
      first_called = false
      Plugins.init_plugins do
        load_plugin 'my_plugin.rb', true
        first_called = true
      end

      second_called = false
      Plugins.init_plugins do
        load_plugin 'my_other_plugin.rb', true, 'custom_plugin_id'
        second_called = true
      end

      (first_called && second_called).should be_true
      Object.const_defined?(:MyPlugin).should be_true
      Object.const_defined?(:MyOtherPlugin).should be_true
    end

    it 'should not allow an init_plugins block inside another' do
      Plugins.init_plugins do
        lambda do
          Plugins.init_plugins
        end.should raise_error
      end
    end

    it 'should be able to load liquid tags' do
      MyPlugin.expects(:register_tags).with('my_plugin')
      Plugins.send(:load_tags!, 'my_plugin', MyPlugin)
    end

    it 'should load liquid tags for loaded plugins' do
      Plugins.expects(:load_tags!).with('my_plugin', ::MyPlugin)
      Plugins.init_plugins do
        load_plugin 'my_plugin.rb', true
      end
    end

    it 'should ensure that only Mongoid models in the init_plugins block use the collection prefix' do
      PluginModel.use_collection_name_prefix?.should be_true
      OtherModel.use_collection_name_prefix?.should be_false
    end

    protected

    def load_plugin(*args)
      Locomotive::Plugins::SpecHelpers.load_plugin(*args)
    end

    class OtherModel
      include Mongoid::Document
    end

  end
end
