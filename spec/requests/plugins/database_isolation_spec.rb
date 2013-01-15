require 'spec_helper'

describe 'Plugin Database Isolation' do

  let(:site) { FactoryGirl.create(:site) }

  before(:each) do
    Locomotive::Public::PagesController.any_instance.stubs(:current_site).returns(site)
    Locomotive::Middlewares::Plugins.any_instance.stubs(:current_site).returns(site)

    Locomotive::Plugins::SpecHelpers.before_each(__FILE__)
    FactoryGirl.create(:plugin_data, plugin_id: 'my_plugin', enabled: true,
      site: site)
  end

  it 'should access a collection prefixed with the current site id' do
    get('/')

    with_collection("#{site.id}__") do
      MyPlugin::Model.collection.name.should == "#{site.id}__my_plugin_models"
      MyPlugin::Model.count.should == 1
    end
  end

  it 'should not access the default collection' do
    MyPlugin::Model.collection.name.should == 'my_plugin_models'
    MyPlugin::Model.count.should == 0

    get('/')

    MyPlugin::Model.collection.name.should == 'my_plugin_models'
    MyPlugin::Model.count.should == 0
  end

  it 'should access the default collection for Locomotive models'

  protected

  def with_collection(name)
    ::Mongoid::Collections.with_collection_name_prefix(name) do
      yield
    end
  end

  # Plugin class

  Locomotive::Plugins::SpecHelpers.define_plugins(__FILE__) do
    class MyPlugin
      include Locomotive::Plugin

      class Model
        include Mongoid::Document
        field :name
      end

      before_filter :create_model_instance
      def create_model_instance
        Model.create!(name: 'new')
      end
    end
  end

end
