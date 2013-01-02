require 'spec_helper'

describe 'Plugin Database Isolation' do

  it 'should access a collection prefixed with the current site id' do
    get('/')

    set_collection(MyPlugin::Model, "#{@site.id}__my_plugin_model")
    MyPlugin::Model.count.should == 1
  end

  it 'should not access the default collection' do
    MyPlugin::Model.collection_name.should == 'my_plugin_model'
    MyPlugin::Model.count.should == 0

    get('/')

    MyPlugin::Model.collection_name.should == 'my_plugin_model'
    MyPlugin::Model.count.should == 0
  end

  protected

  def set_collection(model_class, name)
    model_class.collection_name = name
    model_class.set_collection
  end

end
