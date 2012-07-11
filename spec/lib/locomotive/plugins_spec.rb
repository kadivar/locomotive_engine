require 'spec_helper'

module Locomotive
  module Plugins
    describe Processor do

      before(:each) do
        LocomotivePlugins.register_plugin(MyEnabledPlugin)
        LocomotivePlugins.register_plugin(MyDisabledPlugin)
        @enabled_plugin = LocomotivePlugins.registered_plugins['my_enabled_plugin']
        @disabled_plugin = LocomotivePlugins.registered_plugins['my_disabled_plugin']

        @site = FactoryGirl.build(:site)
        @site.stubs(:enabled_plugins).returns(['my_enabled_plugin'])

        Locomotive::TestController.send(:include, Locomotive::Plugins::Processor)
        @controller = Locomotive::TestController.new
        @controller.stubs(:current_site).returns(@site)
      end

      context 'before_filters' do

        it 'should run all before_filters for enabled plugins' do
          @enabled_plugin.expects(:my_method)
          @controller.run_plugin_before_filters
        end

        it 'should not run any before_filters for disabled plugins' do
          @disabled_plugin.expects(:another_method).never
          @controller.run_plugin_before_filters
        end

      end

      context 'liquid' do

        before(:each) do
          LocomotivePlugins.register_plugin(AnotherEnabledPlugin)
          @another_enabled_plugin = \
            LocomotivePlugins.registered_plugins['another_enabled_plugin']
        end

        it 'should build a container for the plugin liquid drops' do
          container = @controller.plugin_drops
          container_liquid = container.to_liquid
          container_liquid.kind_of?(::Liquid::Drop).should be_true
        end

        it 'should retrieve the liquid drops for enabled plugins with drops' do
          container = @controller.plugin_drops
          container.before_method('my_enabled_plugin').should == @enabled_plugin.to_liquid
          container.before_method('another_enabled_plugin').should be_nil
        end

        it 'should not retrieve the liquid drops for disabled plugins' do
          container = @controller.plugin_drops
          container.before_method('my_disabled_plugin').should be_nil
        end

      end

      protected

      class MyEnabledPlugin

        include Locomotive::Plugin

        before_filter :my_method

        def to_liquid
          @my_drop ||= MyEnabledDrop.new
        end

        def my_method
        end

      end

      class AnotherEnabledPlugin
        include Locomotive::Plugin
      end

      class MyDisabledPlugin

        include Locomotive::Plugin

        before_filter :another_method

        def another_method
        end

        def to_liquid
          @my_drop ||= MyDisabledDrop.new
        end

      end

      class MyEnabledDrop < ::Liquid::Drop
      end

      class MyDisabledDrop < ::Liquid::Drop
      end

    end
  end
end
