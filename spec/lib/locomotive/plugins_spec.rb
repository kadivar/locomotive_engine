require 'spec_helper'

module Locomotive
  module Plugins
    describe Processor do

      before(:each) do
        @site = FactoryGirl.create(:site)

        register_and_enable_plugin(MobileDetectionPlugin)
        register_plugin(LanguagePlugin)

        Locomotive::TestController.send(:include, Locomotive::Plugins::Processor)
        @controller = Locomotive::TestController.new
        @controller.stubs(:current_site).returns(@site)
        @controller.stubs(:params).returns({})
      end

      context 'before_filters' do

        it 'should run all before_filters for enabled plugins' do
          MobileDetectionPlugin.any_instance.expects(:determine_device)
          process_plugins
        end

        it 'should not run any before_filters for disabled plugins' do
          LanguagePlugin.any_instance.expects(:get_language).never
          process_plugins
        end

        it 'should be able to access the controller from the before_filter' do
          @controller.expects(:params).returns({})
          process_plugins
        end

      end

      context 'liquid' do

        before(:each) do
          register_and_enable_plugin(UselessPlugin)
          process_plugins
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

      context 'db_models' do

        before(:each) do
          register_and_enable_plugin(VisitCountPlugin)
        end

        it 'should persist data between requests' do
          plugin = @site.enabled_plugin_objects_by_id['visit_count_plugin']
          plugin.count.should == 0

          process_plugins
          @site.reload

          plugin = @site.enabled_plugin_objects_by_id['visit_count_plugin']
          plugin.count.should == 1
        end

      end

      protected

      def register_plugin(plugin_class)
        LocomotivePlugins.register_plugin(plugin_class)
      end

      def enable_plugin(plugin_id)
        FactoryGirl.create(:plugin_data, :site => @site,
          :plugin_id => plugin_id, :enabled => true)
      end

      def register_and_enable_plugin(plugin_class)
        plugin_id = LocomotivePlugins.default_id(plugin_class)
        register_plugin(plugin_class)
        enable_plugin(plugin_id)
      end

      def process_plugins
        @controller.process_plugins do
        end
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

      class VisitCountPlugin

        include Locomotive::Plugin

        class VisitCounter < Locomotive::Plugin::DBModel
          field :count, default: 0
        end

        has_one :visit_counter, VisitCounter
        before_filter :increment_count

        def count
          get_visit_counter.count
        end

        protected

        def increment_count
          get_visit_counter.count += 1
        end

        def get_visit_counter
          visit_counter || build_visit_counter
        end

      end

    end
  end
end
