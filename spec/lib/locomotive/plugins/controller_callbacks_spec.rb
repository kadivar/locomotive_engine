require 'spec_helper'

module Locomotive
  module Plugins
    describe ControllerCallbacks do

      before(:each) do
        @site = FactoryGirl.create(:site)

        Locomotive::Plugins::SpecHelpers.stub_registered_plugins(
          MobileDetectionPlugin, LanguagePlugin)
        enable_plugin(MobileDetectionPlugin)

        @controller = Locomotive::TestController.new
        @controller.extend(Locomotive::Plugins::ControllerCallbacks)
        @controller.stubs(:current_site).returns(@site)
        @controller.stubs(:params).returns({})
      end

      context 'before_filters' do

        it 'should run all before_filters for enabled plugins' do
          enable_plugin(LanguagePlugin)
          MobileDetectionPlugin.any_instance.expects(:determine_device)
          LanguagePlugin.any_instance.expects(:get_language)
          prepare_plugins_for_request
        end

        it 'should not run any before_filters for disabled plugins' do
          LanguagePlugin.any_instance.expects(:get_language).never
          prepare_plugins_for_request
        end

        it 'should be able to access the controller from the before_filter' do
          @controller.expects(:params).returns({})
          prepare_plugins_for_request
        end

      end

      context 'liquid' do

        before(:each) do
          @context = ::Liquid::Context.new({}, {}, {site: @site}, true)
          @controller.instance_variable_set(:@liquid_context, @context)
        end

        it 'should call setup_liquid_context on enabled plugin objects' do
          enable_plugin(LanguagePlugin)
          MobileDetectionPlugin.any_instance.expects(:setup_liquid_context)
          LanguagePlugin.any_instance.expects(:setup_liquid_context)
          prepare_plugins_for_render
        end

        it 'should not call setup_liquid_context on disabled plugin objects' do
          LanguagePlugin.any_instance.expects(:setup_liquid_context).never
          prepare_plugins_for_render
        end

      end

      protected

      def enable_plugin(plugin_class)
        FactoryGirl.create(:plugin_data, :site => @site,
          :plugin_id => plugin_class.default_plugin_id, :enabled => true)
      end

      %w{request render}.each do |type|
        define_method(:"prepare_plugins_for_#{type}") do |controller = nil|
          controller ||= @controller
          controller.send(:"prepare_plugins_for_#{type}") do
            yield if block_given?
          end
        end
      end

      ## Classes ##

      Locomotive::Plugins.init_plugins do
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
      end

    end
  end
end
