require 'spec_helper'

describe 'Plugin Database Isolation' do

  let(:site) { FactoryGirl.create(:site) }

  before(:each) do
    Locomotive::Public::PagesController.any_instance.stubs(:current_site).returns(site)
    Locomotive::Plugins::SpecHelpers.before_each(__FILE__)
    reset_collection(MyPlugin::Model)
    FactoryGirl.create(:plugin_data, plugin_id: 'my_plugin', enabled: true,
      site: site)
  end

  it 'should access a collection prefixed with the current site id' do
    get('/')

    set_collection(MyPlugin::Model, "#{site.id}__my_plugin_model")
    MyPlugin::Model.count.should == 1
  end

  it 'should not access the default collection' do
    MyPlugin::Model.collection_name.should == 'my_plugin_models'
    MyPlugin::Model.count.should == 0

    get('/')

    MyPlugin::Model.collection_name.should == 'my_plugin_models'
    MyPlugin::Model.count.should == 0
  end

  it 'should access the default collection for Locomotive models'

  protected

  def set_collection(model_class, name)
    model_class.collection_name = name
    model_class.send(:set_collection)
  end

  def reset_collection(model_class)
    model_class.collection_name = model_class.name.collectionize
    model_class.send(:_collection=, nil)
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
