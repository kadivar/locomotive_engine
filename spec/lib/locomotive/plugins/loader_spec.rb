
require 'spec_helper'

module Locomotive
  module Plugins
    describe Loader do

      before(:each) do
        setup_load_path
      end

      after(:each) do
        clear!
      end

      it 'should log a warning if a plugin is loaded before init_plugins' do
        load 'my_plugin.rb'
        Locomotive::Logger.expects(:warn)
        Locomotive.init_plugins
      end

      it 'should log a warning if a plugin is loaded after init_plugins' do
        Locomotive.init_plugins
        Locomotive::Logger.expects(:warn)
        load 'my_plugin.rb'
      end

      it 'should load plugin without warning inside the init_plugins block' do
        Locomotive::Logger.expects(:warn).never
        Locomotive.init_plugins do
          load 'my_plugin.rb'
        end
        Object.const_defined?(:MyPlugin).should be_true
      end

      it 'should require all plugins from Bundler' do
        Bundler.expects(:require).with(:locomotive_plugins)
        Locomotive::Plugins::Loader.bundler_require
      end

      it 'should call init_plugins when requiring from Bundler' do
        Loader.expects(:init_plugins)
        Locomotive::Plugins::Loader.bundler_require
      end

      it 'should not log a warning when requiring plugins from Bundler' do
        Locomotive::Logger.expects(:warn).never

        def Bundler.require(*args)
          Kernel.load 'my_plugin.rb'
        end

        Locomotive::Plugins::Loader.bundler_require
      end

      it 'should allow for multiple init blocks' do
        Locomotive::Logger.expects(:warn).never
        Locomotive.init_plugins do
          load 'my_plugin.rb'
        end
        Locomotive.init_plugins do
          load 'my_other_plugin.rb'
        end

        Object.const_defined?(:MyPlugin).should be_true
        Object.const_defined?(:MyOtherPlugin).should be_true
      end

      it 'should register valid plugins'

      it 'should set up database collection prefix handling'

      protected

      def setup_load_path
        $LOAD_PATH.unshift(File.join(File.dirname(__FILE__),
          'loader_spec_files'))
      end

      def clear!
        Locomotive::Plugins::Loader.instance_variable_set(:@initialized, nil)
        Locomotive::Plugin.instance_variable_set(:@plugin_classes, Set.new)
        Locomotive::Plugin.instance_variable_set(:@trackers, [])
        Object.send(:remove_const, :MyPlugin) if Object.const_defined?(:MyPlugin)
      end

    end
  end
end
