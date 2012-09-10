require 'spec_helper'

describe Locomotive::Extensions::Site::Plugins do

  let(:site) { FactoryGirl.create(:site, :subdomain => 'test') }

  before(:each) do
    add_plugins
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
      site.plugins.first[:plugin_config].should == { 'key' => 'value' }
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

      enabled_plugin_ids = site.enabled_plugins.collect(&:plugin_id)
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

      enabled_plugin_ids = site.enabled_plugins.collect(&:plugin_id)
      enabled_plugin_ids.should be_empty
    end

    it 'leaves plugins as they were if there is no change' do
      old_enabled_plugins = site.enabled_plugins
      plugins_array = site.plugins.clone
      site_plugins = plugins_array
      site.enabled_plugins.should == old_enabled_plugins
    end

    it 'sets config parameters on enabled plugins' do
      site.plugins = {
        '0' => {
          :plugin_id => 'mobile_detection',
          :plugin_enabled => 'true',
          :plugin_config => { 'key' => 'value' }
        },
        '1' => {
          :plugin_id => 'language_detection',
          :plugin_enabled => 'false'
        }
      }

      site.enabled_plugins.first.config.should == { 'key' => 'value' }
    end

  end

  protected

  class MobileDetection
    include Locomotive::Plugin
  end

  class LanguageDetection
    include Locomotive::Plugin
  end

  def add_plugins
    register_plugins
    enable_plugins
  end

  def register_plugins
    LocomotivePlugins.register_plugin(MobileDetection)
    LocomotivePlugins.register_plugin(LanguageDetection)
  end

  def enable_plugins
    FactoryGirl.create(:enabled_plugin,
                       :plugin_id => 'mobile_detection',
                       :config => { 'key' => 'value' },
                       :site => site)
  end

end
