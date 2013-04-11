
require 'spec_helper.rb'

module Mongoid
  describe Document do

    it 'should allow tracking of models which include Mongoid::Document' do
      klasses = []
      Mongoid::Document.add_tracker do |klass|
        klasses << klass
      end
      MyModel.send(:include, Mongoid::Document)

      klasses.should == [ MyModel ]
    end

    protected

    class MyModel
      include Mongoid::Document
    end

  end
end
