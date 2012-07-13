require 'spec_helper'

module Locomotive
  module Plugins
    describe Processor do

      before(:each) do
        @enabled_plugin = register_and_enable_plugin(MyEnabledPlugin)
        @disabled_plugin = register_plugin(MyDisabledPlugin)

        @site = FactoryGirl.build(:site)
        @site.stubs(:enabled_plugins).returns(@enabled_plugins)

        Locomotive::TestController.send(:include, Locomotive::Plugins::Processor)
        @controller = Locomotive::TestController.new
        @controller.stubs(:current_site).returns(@site)
      end

      context 'before_filters' do

        it 'should run all before_filters for enabled plugins' do
          @enabled_plugin.expects(:my_method)
          @controller.process_plugins
        end

        it 'should not run any before_filters for disabled plugins' do
          @disabled_plugin.expects(:another_method).never
          @controller.process_plugins
        end

        it 'should be able to access the controller from the before_filter' do
          @controller.expects(:params)
          @controller.process_plugins
        end

      end

      context 'liquid' do

        before(:each) do
          @another_enabled_plugin = register_and_enable_plugin(AnotherEnabledPlugin)
          @controller.process_plugins
        end

        it 'should build a container for the plugin liquid drops' do
          container = @controller.plugin_drops_container
          container_liquid = container.to_liquid
          container_liquid.kind_of?(::Liquid::Drop).should be_true
        end

        it 'should retrieve the liquid drops for enabled plugins with drops' do
          container = @controller.plugin_drops_container
          container['my_enabled_plugin'].should == @enabled_plugin.to_liquid
          container['another_enabled_plugin'].should be_nil
        end

        it 'should not retrieve the liquid drops for disabled plugins' do
          container = @controller.plugin_drops_container
          container['my_disabled_plugin'].should be_nil
        end

      end

      context 'content entry scoping' do

        before(:each) do
          @controller.process_plugins
        end

        it 'should add a scope for enabled plugins' do
          scopes = @controller.plugin_scope_hash
          scopes['$and'].count.should == 1
          scopes['$and'].should include(@enabled_plugin.content_entry_scope)
        end

        it 'should not add a scope for disabled plugins' do
          scopes = @controller.plugin_scope_hash
          scopes['$and'].should_not include(@disabled_plugin.content_entry_scope)
        end

        it 'should not add a scope for an enabled plugin which does not specify one' do
          @another_enabled_plugin = register_and_enable_plugin(AnotherEnabledPlugin)
          @controller.process_plugins
          scopes = @controller.plugin_scope_hash
          scopes['$and'].count.should == 1
          scopes['$and'].should include(@enabled_plugin.content_entry_scope)
        end

        it 'should add all scopes for multiple enabled plugins' do
          @plugin_with_scope = register_and_enable_plugin(PluginWithScope)
          @controller.process_plugins
          scopes = @controller.plugin_scope_hash
          scopes['$and'].count.should == 2
          scopes['$and'].should include(@enabled_plugin.content_entry_scope)
          scopes['$and'].should include(@plugin_with_scope.content_entry_scope)
        end

      end

      protected

      def register_plugin(plugin_class)
        LocomotivePlugins.register_plugin(plugin_class)
        plugin_id = LocomotivePlugins.default_id(plugin_class)
        LocomotivePlugins.registered_plugins[plugin_id]
      end

      def enable_plugin(plugin_id)
        @enabled_plugins ||= []
        @enabled_plugins << plugin_id
      end

      def register_and_enable_plugin(plugin_class)
        plugin_id = LocomotivePlugins.default_id(plugin_class)
        enable_plugin(plugin_id)
        register_plugin(plugin_class)
      end

      ## Classes ##

      class MyEnabledPlugin

        include Locomotive::Plugin

        before_filter :my_method

        def to_liquid
          @my_drop ||= MyEnabledDrop.new
        end

        def content_entry_scope
          { :my_field.gte => 5 }
        end

        def my_method
          # Access params
          self.controller.params
        end

      end

      class AnotherEnabledPlugin
        include Locomotive::Plugin
      end

      class PluginWithScope
        include Locomotive::Plugin

        def content_entry_scope
          { :my_field => :my_value }
        end
      end

      class MyDisabledPlugin

        include Locomotive::Plugin

        before_filter :another_method

        def another_method
        end

        def to_liquid
          @my_drop ||= MyDisabledDrop.new
        end

        def content_entry_scope
          { :awesomeness => 100 }
        end

      end

      class MyEnabledDrop < ::Liquid::Drop
      end

      class MyDisabledDrop < ::Liquid::Drop
      end

    end
  end
end
