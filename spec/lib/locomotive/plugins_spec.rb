require 'spec_helper'

module Locomotive
  module Plugins
    describe Processor do

      before(:each) do
        register_and_enable_plugin(MobileDetectionPlugin)
        register_plugin(LanguagePlugin)

        @site = FactoryGirl.build(:site)
        @site.stubs(:plugin_data).returns(@plugin_data)

        Locomotive::TestController.send(:include, Locomotive::Plugins::Processor)
        @controller = Locomotive::TestController.new
        @controller.stubs(:current_site).returns(@site)
        @controller.stubs(:params).returns({})
      end

      context 'before_filters' do

        it 'should run all before_filters for enabled plugins' do
          MobileDetectionPlugin.any_instance.expects(:determine_device)
          @controller.process_plugins
        end

        it 'should not run any before_filters for disabled plugins' do
          LanguagePlugin.any_instance.expects(:get_language).never
          @controller.process_plugins
        end

        it 'should be able to access the controller from the before_filter' do
          @controller.expects(:params).returns({})
          @controller.process_plugins
        end

      end

      context 'liquid' do

        before(:each) do
          register_and_enable_plugin(UselessPlugin)
          @controller.process_plugins
        end

        it 'should supply the enabled plugins' do
          @controller.plugins.collect(&:class).should == \
            [ MobileDetectionPlugin, UselessPlugin ]
        end

        it 'should build a container for the plugin liquid drops' do
          container = @controller.plugin_drops_container
          container_liquid = container.to_liquid
          container_liquid.kind_of?(::Liquid::Drop).should be_true
        end

        it 'should retrieve the liquid drops for enabled plugins with drops' do
          @first_enabled_plugin = @controller.plugins.first
          container = @controller.plugin_drops_container
          container['mobile_detection_plugin'].class.should == @first_enabled_plugin.to_liquid.class
          container['useless_plugin'].should be_nil
        end

        it 'should not retrieve the liquid drops for disabled plugins' do
          container = @controller.plugin_drops_container
          container['language_plugin'].should be_nil
        end

      end

      protected

      def register_plugin(plugin_class)
        LocomotivePlugins.register_plugin(plugin_class)
      end

      def enable_plugin(plugin_id)
        @plugin_data ||= []
        @plugin_data << FactoryGirl.create(:plugin_data,
                                           :plugin_id => plugin_id,
                                           :enabled => true)
      end

      def register_and_enable_plugin(plugin_class)
        plugin_id = LocomotivePlugins.default_id(plugin_class)
        enable_plugin(plugin_id)
        register_plugin(plugin_class)
      end

      ## Classes ##

      class MobileDetectionPlugin

        include Locomotive::Plugin

        attr_accessor :mobile

        before_filter :determine_device

        def to_liquid
          @my_drop ||= MobileDetectionDrop.new
        end

        def determine_device
          # Access params
          if self.controller.params[:mobile]
            self.mobile = true
          else
            self.mobile = false
          end
        end

      end

      class UselessPlugin
        include Locomotive::Plugin
      end

      class LanguagePlugin

        include Locomotive::Plugin

        attr_accessor :language

        before_filter :get_language

        def get_language
          self.language = 'en'
        end

        def to_liquid
          @my_drop ||= LanguageDrop.new
        end

      end

      class MobileDetectionDrop < ::Liquid::Drop
      end

      class LanguageDrop < ::Liquid::Drop
      end

    end
  end
end
