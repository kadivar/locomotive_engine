require 'spec_helper'

describe Locomotive::Extensions::Site::Plugins do

  let(:site) { FactoryGirl.create(:site, :subdomain => 'test') }

  before(:each) do
    Locomotive::Plugins::SpecHelpers.before_each(__FILE__)
    enable_plugins
  end

  describe '#plugins' do

    it 'includes all registered plugins' do
      site.plugins.count.should == 2
      plugin_ids = site.plugins.collect { |p| p[:plugin_id] }
      plugin_ids.should include('mobile_detection')
      plugin_ids.should include('language_detection')
    end

    it 'shows which plugins are enabled' do
      site.plugins.detect do |p|
        p[:plugin_id] == 'mobile_detection'
      end[:plugin_enabled].should be_true

      site.plugins.detect do |p|
        p[:plugin_id] == 'language_detection'
      end[:plugin_enabled].should_not be_true
    end

    it 'includes the plugin config' do
      site.plugins.first[:plugin_config].should == { :key => 'value' }
    end

  end

  describe '#plugins=' do

    it 'enables a disabled plugin' do
      site.plugins = {
        '0' => {
          :plugin_id => 'mobile_detection',
          :plugin_enabled => 'true'
        },
        '1' => {
          :plugin_id => 'language_detection',
          :plugin_enabled => 'true'
        }
      }

      enabled_plugin_ids = site.plugins.select do |plugin|
        plugin[:plugin_enabled]
      end.collect { |plugin| plugin[:plugin_id] }
      enabled_plugin_ids.count.should == 2
      enabled_plugin_ids.should include('mobile_detection')
      enabled_plugin_ids.should include('language_detection')
    end

    it 'disables an enabled plugin' do
      site.plugins = {
        '0' => {
          :plugin_id => 'mobile_detection',
          :plugin_enabled => 'false'
        },
        '1' => {
          :plugin_id => 'language_detection',
          :plugin_enabled => 'false'
        }
      }

      enabled_plugin_ids = site.plugins.select do |plugin|
        plugin[:plugin_enabled]
      end.collect { |plugin| plugin[:plugin_id] }
      enabled_plugin_ids.should be_empty
    end

    it 'leaves plugins as they were if there is no change' do
      old_plugins = site.plugins
      plugins_array = site.plugins.clone

      plugins_indexed_hash = {}.tap do |h|
        plugins_array.each_with_index do |plugin_hash, index|
          h[index.to_s] = plugin_hash
        end
      end

      site.plugins = plugins_indexed_hash
      site.plugins.should == old_plugins
    end

    it 'sets config parameters on plugins' do
      site.plugins = {
        '0' => {
          :plugin_id => 'mobile_detection',
          :plugin_enabled => 'true',
          :plugin_config => { 'key' => 'value' }
        },
        '1' => {
          :plugin_id => 'language_detection',
          :plugin_enabled => 'false',
          :plugin_config => { 'key2' => 'value2' }
        }
      }

      site.plugins.first[:plugin_config].should == { 'key' => 'value' }
      site.plugins.last[:plugin_config].should == { 'key2' => 'value2' }
    end

    it 'should store boolean fields properly' do
      site.plugins = {
        '0' => {
          :plugin_id => 'mobile_detection',
          :plugin_enabled => 'true',
          :plugin_config => { 'boolean_key' => 'true' },
          :plugin_config_boolean_fields => [ 'boolean_key' ]
        },
        '1' => {
          :plugin_id => 'language_detection',
          :plugin_enabled => 'false',
          :plugin_config => { 'boolean_key2' => 'false' },
          :plugin_config_boolean_fields => [ 'boolean_key2' ]
        }
      }

      site.plugins.first[:plugin_config].should == { 'boolean_key' => true }
      site.plugins.last[:plugin_config].should == { 'boolean_key2' => false }
    end

    it 'should ignore attributes which are not in the params' do
      site.plugins = {
        '0' => {
          :plugin_id => 'mobile_detection',
        },
        '1' => {
          :plugin_id => 'language_detection',
        }
      }

      site.plugins.first[:plugin_enabled].should be_true
      site.plugins.first[:plugin_config].should == { :key => 'value' }

      site.plugins.last[:plugin_enabled].should be_false
      site.plugins.last[:plugin_config].should == {}
    end

  end

  it 'allows only one plugin wrapper with a given ID on each site' do
    site2 = FactoryGirl.create(:site, :subdomain => 'test2')

    lambda do
      FactoryGirl.create(:plugin_data,
                         :plugin_id => 'mobile_detection',
                         :site => site2)
    end.should_not raise_error

    lambda do
      FactoryGirl.create(:plugin_data,
                         :plugin_id => 'mobile_detection',
                         :site => site2)
    end.should raise_error

    lambda do
      FactoryGirl.create(:plugin_data,
                         :plugin_id => 'mobile_detection',
                         :site => site)
    end.should raise_error
  end

  it 'supplies the plugin object for a given ID (needed for the liquid context)' do
    site.plugin_object_for_id('mobile_detection').class.should == MobileDetection
    site.plugin_object_for_id('language_detection').class.should == LanguageDetection
  end

  protected

  Locomotive::Plugins::SpecHelpers.define_plugins(__FILE__) do
    class MobileDetection
      include Locomotive::Plugin

      module Filters
        def add_http_prefix(input)
          if input.start_with?('http://')
            input
          else
            "http://#{input}"
          end
        end
      end

      def self.liquid_filters
        Filters
      end

    end

    class LanguageDetection
      include Locomotive::Plugin

      module Filters
        def upcase(input)
          input.upcase
        end
      end

      def self.liquid_filters
        Filters
      end

    end
  end

  def enable_plugins
    FactoryGirl.create(:plugin_data,
                      :plugin_id => 'mobile_detection',
                      :config => { :key => 'value' },
                      :enabled => true,
                      :site => site)
    FactoryGirl.create(:plugin_data,
                      :plugin_id => 'language_detection',
                      :enabled => false,
                      :site => site)
  end

end
