require 'spec_helper'

module Locomotive
  module Plugins
    describe JS3 do

      let(:site) { FactoryGirl.create(:site, :subdomain => 'test') }

      before(:each) do
        FactoryGirl.create(:plugin_data,
                          :plugin_id => 'plugin_with_js3',
                          :enabled => true,
                          :site => site)
        Thread.current[:site] = site
      end

      it 'should store context hashes' do
        Plugins.send(:context_storage)['plugin_with_js3'].class.should be Hash
        Plugins.send(:context_storage)['plugin_with_js3'].keys.should eq [:variable, :method]
      end

      it 'should be able to generate a js3 context' do
        context = Plugins.js3_context
        context.class.should be V8::Context
        context['plugin_with_js3_variable'].should eq "string"
        context.eval("plugin_with_js3_method('word', 3)").should eq "wordwordword"
      end
    end
  end
end
