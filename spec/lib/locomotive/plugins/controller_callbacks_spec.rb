require 'spec_helper'

module Locomotive
  module Plugins
    describe ControllerCallbacks do

      before(:each) do
        @site = FactoryGirl.create(:site)

        register_and_enable_plugin(MobileDetectionPlugin)
        register_plugin(LanguagePlugin)

        Locomotive::TestController.send(:include,
          Locomotive::Plugins::ControllerCallbacks)

        @controller = Locomotive::TestController.new
        @controller.stubs(:current_site).returns(@site)
        @controller.stubs(:params).returns({})
      end

      context 'before_filters' do

        it 'should run all before_filters for enabled plugins' do
          enable_plugin('language_plugin')
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
          enable_plugin('language_plugin')
          MobileDetectionPlugin.any_instance.expects(:setup_liquid_context)
          LanguagePlugin.any_instance.expects(:setup_liquid_context)
          prepare_plugins_for_render
        end

        it 'should not call setup_liquid_context on disabled plugin objects' do
          LanguagePlugin.any_instance.expects(:setup_liquid_context).never
          prepare_plugins_for_render
        end

      end

      # TODO: remove all of this
=begin
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

        it 'should use a different container on each site' do
          @old_site = @site
          @old_controller = @controller

          @site = FactoryGirl.create(:site, subdomain: 'new-subdomain')
          register_and_enable_plugin(VisitCountPlugin)

          @controller = Locomotive::TestController.new
          @controller.stubs(:current_site).returns(@site)
          @controller.stubs(:params).returns({})

          old_container_id = nil
          process_plugins(@old_controller) do
            old_plugin = @old_site.enabled_plugin_objects_by_id[
              'visit_count_plugin']
            old_container_id = old_plugin.db_model_container.id
          end

          container_id = nil
          process_plugins(@controller) do
            plugin = @site.enabled_plugin_objects_by_id[
              'visit_count_plugin']
            container_id = plugin.db_model_container.id
          end

          container_id.should_not == old_container_id
        end

      end
=end

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

      %w{request render}.each do |type|
        define_method(:"prepare_plugins_for_#{type}") do |controller = nil|
          controller ||= @controller
          controller.send(:"prepare_plugins_for_#{type}") do
            yield if block_given?
          end
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
