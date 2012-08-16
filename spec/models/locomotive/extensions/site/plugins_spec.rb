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

  end

  describe '#plugins=' do

    it 'enables a disabled plugin'

    it 'disables an enabled plugin'

    it 'leaves plugins as they were if there is no change'

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
    FactoryGirl.create(:enabled_plugin, :plugin_id => 'mobile_detection', :site => site)
  end

end
