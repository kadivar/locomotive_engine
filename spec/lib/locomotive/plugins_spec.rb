
require 'spec_helper'

module Locomotive
  describe Plugins do

    before(:each) do
      Locomotive::Plugins::SpecHelpers.before_each
    end

    it 'should log a warning if a plugin is loaded before init_plugins' do
      load 'my_plugin.rb'
      Locomotive::Logger.expects(:warn)
      Plugins.init_plugins
    end

    it 'should log a warning if a plugin is loaded after init_plugins' do
      Plugins.init_plugins
      Locomotive::Logger.expects(:warn)
      load 'my_plugin.rb'
    end

    it 'should load plugin without warning inside the init_plugins block' do
      Locomotive::Logger.expects(:warn).never
      Plugins.init_plugins do
        load 'my_plugin.rb'
      end
      Object.const_defined?(:MyPlugin).should be_true
    end

    it 'should require all plugins from Bundler' do
      Bundler.expects(:require).with(:locomotive_plugins)
      Plugins.bundler_require
    end

    it 'should call init_plugins when requiring from Bundler' do
      Plugins.expects(:init_plugins)
      Plugins.bundler_require
    end

    it 'should not log a warning when requiring plugins from Bundler' do
      Locomotive::Logger.expects(:warn).never

      def Bundler.require(*args)
        Kernel.load 'my_plugin.rb'
      end

      Plugins.bundler_require
    end

    it 'should allow for multiple init blocks' do
      Locomotive::Logger.expects(:warn).never
      Plugins.init_plugins do
        load 'my_plugin.rb'
      end
      Plugins.init_plugins do
        load 'my_other_plugin.rb'
      end

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

    it 'should register loaded plugins' do
      Plugins.expects(:register_plugin!)
      Plugins.init_plugins do
        load 'my_plugin.rb'
      end
    end

    it 'should include load tags for loaded plugins'

  end
end
