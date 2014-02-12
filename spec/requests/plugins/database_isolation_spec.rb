require 'spec_helper'

describe 'Plugin Database Isolation' do

  let(:site) { FactoryGirl.create(:site) }

  before(:each) do
    stub_i18n_fallbacks

    Locomotive::Public::PagesController.any_instance.stubs(:current_site).returns(site)
    Locomotive::Middlewares::Plugins.any_instance.stubs(:current_site).returns(site)

    FactoryGirl.create(:plugin_data, plugin_id: 'my_db_plugin', enabled: true,
      site: site)
  end

  it 'should access a collection prefixed with the current site id' do
    get('/')

    with_collection_prefix("#{site.id}__") do
      MyDBPlugin::Model.collection.name.should == "#{site.id}__my_db_plugin_models"
      MyDBPlugin::Model.count.should == 1
    end
  end

  it 'should not access the default collection' do
    MyDBPlugin::Model.collection.name.should == 'my_db_plugin_models'
    MyDBPlugin::Model.count.should == 0

    get('/')

    MyDBPlugin::Model.collection.name.should == 'my_db_plugin_models'
    MyDBPlugin::Model.count.should == 0
  end

  it 'should access the default collection for Locomotive models' do
    prefix = "#{site.id}__"
    with_collection_prefix(prefix) do
      FactoryGirl.create(:page, slug: 'my-new-page', parent: site.pages.first)
    end

    Locomotive::Page.collection.name.start_with?(prefix).should be_false
    Locomotive::Page.all.collect(&:slug).should include('my-new-page')
  end

  protected

  def with_collection_prefix(name)
    ::Mongoid::Sessions.with_collection_name_prefix(name) do
      yield
    end
  end

  def stub_i18n_fallbacks
    # For some reason this method is making other specs fail. Stub it out
    Locomotive::Public::PagesController.any_instance.stubs(:setup_i18n_fallbacks).returns(true)
  end

  # Plugin class

  Locomotive::Plugins.init_plugins do
    class MyDBPlugin
      include Locomotive::Plugin

      class Model
        include Mongoid::Document
        field :name
      end

      before_page_render :create_model_instance
      def create_model_instance
        Model.create!(name: 'new')
      end
    end
  end

end
