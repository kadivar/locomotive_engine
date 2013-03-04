require 'spec_helper'

describe 'Rack App Mounting' do

  let(:site) { FactoryGirl.create(:site) }

  before(:each) do
    stub_i18n_fallbacks

    Locomotive::Public::PagesController.any_instance.stubs(:current_site).returns(site)
    Locomotive::Plugins::RackAppPassthrough.any_instance.stubs(:fetch_site).returns(site)

    @plugin_data = FactoryGirl.create(:plugin_data,
      plugin_id: 'plugin_with_rack_app', enabled: true, site: site)
  end

  it 'should call the plugin rack app when the plugin is enabled' do
    get('/locomotive/plugins/plugin_with_rack_app/path')
    response.body.should == 'Rack app successful!'
  end

  it 'should not call the plugin rack app when the plugin is disabled' do
    @plugin_data.enabled = false
    @plugin_data.save!

    get('/locomotive/plugins/plugin_with_rack_app/path')
    response.body.should == 'Content of the 404 page'
  end

  it 'should not try to call the plugin rack app if it does not exist' do
    FactoryGirl.create(:plugin_data, plugin_id: 'other_plugin', enabled: true,
      site: site)
    get('/locomotive/plugins/other_plugin/path')
    response.body.should == 'Content of the 404 page'
  end

  it 'should not try to call the plugin rack app if the plugin does not exist' do
    get('/locomotive/plugins/no_plugin/path')
    response.body.should == 'Content of the 404 page'
  end

  it 'should be able to access rack app paths and URLs from regular request' do
    Locomotive::Middlewares::Plugins.mountpoint_host = 'https://www.example.com:1234'
    plugin_object = site.plugin_object_for_id('plugin_with_rack_app')
    plugin_object.rack_app_full_path('/my/path').should ==
      '/locomotive/plugins/plugin_with_rack_app/my/path'
    plugin_object.rack_app_full_url('/my/path').should ==
      'https://www.example.com:1234/locomotive/plugins/plugin_with_rack_app/my/path'
  end

  protected

  def stub_i18n_fallbacks
    # For some reason this method is making other specs fail. Stub it out
    Locomotive::Public::PagesController.any_instance.stubs(:setup_i18n_fallbacks).returns(true)
  end

end
