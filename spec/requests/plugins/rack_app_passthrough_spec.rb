require 'spec_helper'

describe 'Rack App Passthrough' do

  let(:site) { FactoryGirl.create(:site) }

  before(:each) do
    stub_i18n_fallbacks

    Locomotive::Public::PagesController.any_instance.stubs(:current_site).returns(site)

    Locomotive::Plugins::SpecHelpers.before_each(__FILE__)
    FactoryGirl.create(:plugin_data, plugin_id: 'my_plugin', enabled: true,
      site: site)
  end

  it 'should call the plugin rack app when the plugin is enabled' do
    get('/')

    response.body.should == 'Rack app successful!'
  end

  it 'should not call the plugin rack app when the plugin is disabled'

  it 'should not try to call the plugin rack app if it does not exist'

  protected

  def stub_i18n_fallbacks
    # For some reason this method is making other specs fail. Stub it out
    Locomotive::Public::PagesController.any_instance.stubs(:setup_i18n_fallbacks).returns(true)
  end

  # Plugin class

  Locomotive::Plugins::SpecHelpers.define_plugins(__FILE__) do
    class MyPlugin
      include Locomotive::Plugin

      def self.rack_app
        Proc.new do |env|
          [200, {}, ['Rack app successful!']]
        end
      end
    end
  end

end
