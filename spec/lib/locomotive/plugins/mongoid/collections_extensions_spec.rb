
require 'spec_helper.rb'

module Mongoid
  describe Collections do

    it 'should allow models to be flagged as needing to use a prefix' do
      MyModel.use_collection_name_prefix?.should be_false
      MyModel.use_collection_name_prefix = true
      MyModel.use_collection_name_prefix?.should be_true
    end

    it 'it should generate collections with the given prefix' do
      prefixed_collection_name = 'prefix_mongoid_my_models'

      MyModel.collection.name.should_not == prefixed_collection_name

      Mongoid::Collections.with_collection_name_prefix('prefix_') do
        MyModel.collection.name.should == prefixed_collection_name
      end

      MyModel.collection.name.should_not == prefixed_collection_name
    end

    it 'should not use a prefix if the model is not flagged'

    it 'should regenerate the collection only if the prefix has changed'

    it 'should allow tracking of models which include Mongoid::Document'

    protected

    class MyModel
      include Mongoid::Document
    end

  end
end
