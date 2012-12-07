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
          @context = ::Liquid::Context.new({}, {}, {site: @site}, true)
          @controller.send(:add_plugin_data_to_liquid_context, @context)
        end

        it 'should add a container for the plugin liquid drops' do
          container = @context['plugins']
          container_liquid = container.to_liquid
          container_liquid.kind_of?(::Liquid::Drop).should be_true
        end

        it 'should add the liquid drops for enabled plugins with drops' do
          @first_enabled_plugin = @site.enabled_plugin_objects_by_id.values.first
          container = @context['plugins']
          container['mobile_detection_plugin'].class.should == @first_enabled_plugin.to_liquid.class
          container['useless_plugin'].should be_nil
          container['language_plugin'].should be_nil
        end

        it 'should add a set of enabled liquid tags' do
          @context.registers[:enabled_plugin_tags].size.should == 1
          @context.registers[:enabled_plugin_tags].should include(MobileDetectionPlugin::Tag::TagSubclass)
        end

        it 'should add filters for enabled plugins' do
          @context.strainer.mobile_detection_plugin_filter('input').should == 'input'
          expect do
            @context.strainer.language_plugin_filter('input')
          end.to raise_error
        end

        it 'should add the plugin object to the context when calling filters' do
          obj = Object.new
          obj.extend(Locomotive::Plugin::Liquid::PrefixedFilterModule)
          class << obj
            attr_accessor :context
          end
          obj.context = @context

          helper = Locomotive::Plugins::LiquidContextHelpers
          helper.expects(:add_plugin_object_to_context).with(
            'mobile_detection_plugin', @context)

          obj.send(:filter_method_called, 'mobile_detection_plugin', 'method') do
          end
        end

        it 'should add the plugin object to the context when rendering tags' do
          obj = Object.new
          obj.extend(Locomotive::Plugin::Liquid::TagSubclassMethods)

          helper = Locomotive::Plugins::LiquidContextHelpers
          helper.expects(:add_plugin_object_to_context).with(
            'mobile_detection_plugin', @context)

          obj.send(:rendering_tag, 'mobile_detection_plugin', true, @context) do
          end
        end

        context 'add_plugin_object_to_context' do

          before(:each) do
            @helper = Locomotive::Plugins::LiquidContextHelpers
          end

          it 'should add the object to the context' do
            did_yield = false
            @helper.send(:add_plugin_object_to_context,
                'mobile_detection_plugin', @context) do
              did_yield = true
              @context.registers[:plugin_object].class.should == MobileDetectionPlugin
            end
            did_yield.should be_true
            @context.registers[:plugin_object].should be_nil
          end

          it 'should reset the context object' do
            initial_object = 'initial'
            @context.registers[:plugin_object] = initial_object

            did_yield = false
            @helper.send(:add_plugin_object_to_context,
                'mobile_detection_plugin', @context) do
              did_yield = true
              @context.registers[:plugin_object].class.should == MobileDetectionPlugin
            end
            did_yield.should be_true
            @context.registers[:plugin_object].should == initial_object
          end

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
        @controller.send(:process_plugins) do
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

        module Filter
          def filter(input)
            input
          end
        end

        def self.liquid_filters
          Filter
        end

        class Tag
        end

        def self.liquid_tags
          { :tag => Tag }
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

        module Filter
          def filter(input)
            input
          end
        end

        def self.liquid_filters
          Filter
        end

        class Tag
        end

        def self.liquid_tags
          { :tag => Tag }
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

        def initialize_plugin
          build_visit_counter unless visit_counter
        end

        def count
          visit_counter.count
        end

        protected

        def increment_count
          visit_counter.count += 1
        end

      end

    end
  end
end
