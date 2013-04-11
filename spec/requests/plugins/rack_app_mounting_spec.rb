require 'spec_helper'

describe 'Rack App Mounting' do

  let(:site) { FactoryGirl.create(:site) }

  before(:each) do
    stub_i18n_fallbacks

    Locomotive::Public::PagesController.any_instance.stubs(:current_site).returns(site)
    Locomotive::Middlewares::Plugins.stubs(:current_site).returns(site)
    Locomotive::Middlewares::Plugins.any_instance.stubs(:current_site).returns(site)

    @plugin_data = plugin_ids.map do |plugin_id|
      FactoryGirl.create(:plugin_data, plugin_id: plugin_id, enabled: true,
        site: site)
    end
  end

  it 'should call the plugin rack app when the plugin is enabled' do
    plugin_ids.each do |plugin_id|
      get("/locomotive/plugins/#{plugin_id}/path")
      response.body.should == 'Rack app successful!'
    end
  end

  it 'should not call the plugin rack app when the plugin is disabled' do
    @plugin_data.each do |plugin_data|
      plugin_data.enabled = false
      plugin_data.save!
    end

    plugin_ids.each do |plugin_id|
      get("/locomotive/plugins/#{plugin_id}/path")
      response.body.should == 'Content of the 404 page'
    end
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

    plugin_ids.each do |plugin_id|
      plugin_object = site.plugin_object_for_id(plugin_id)
      plugin_object.rack_app_full_path('/my/path').should ==
        "/locomotive/plugins/#{plugin_id}/my/path"
      plugin_object.rack_app_full_url('/my/path').should ==
        "https://www.example.com:1234/locomotive/plugins/#{plugin_id}/my/path"
    end
  end

  it 'should handle weird URL paths' do
    get('/locomotive//plugins//plugin_with_rack_app//path//')
    response.body.should == 'Rack app successful!'

    get('locomotive//plugins//plugin_with_rack_app//path//')
    response.body.should == 'Rack app successful!'

    get('/locomotive//plugins//no_plugin//path//')
    response.body.should == 'Content of the 404 page'

    get('locomotive//plugins//no_plugin//path//')
    response.body.should == 'Content of the 404 page'
  end

  it 'should call rack_app_request callbacks when required' do
    PluginWithRackApp.any_instance.expects(:before_request)
    get('/locomotive/plugins/plugin_with_rack_app/path')

    PluginWithRackApp.any_instance.expects(:before_request).never
    get('/')
  end

  it 'should set the plugin_object' do
    called = false
    PluginWithRackApp::RackApp.block = Proc.new do
      called = true
      PluginWithRackApp::RackApp.plugin_object.should_not be_nil
      PluginWithRackApp::RackApp.plugin_object.class.should == PluginWithRackApp
    end

    called.should be_false
    PluginWithRackApp::RackApp.plugin_object.should be_nil

    get('/locomotive/plugins/plugin_with_rack_app/path')

    called.should be_true
    PluginWithRackApp::RackApp.plugin_object.should be_nil
  end

  protected

  def plugin_ids
    %w{plugin_with_rack_app plugin_with_proc plugin_with_no_call}
  end

  def stub_i18n_fallbacks
    # For some reason this method is making other specs fail. Stub it out
    Locomotive::Public::PagesController.any_instance.stubs(:setup_i18n_fallbacks).returns(true)
  end

end
