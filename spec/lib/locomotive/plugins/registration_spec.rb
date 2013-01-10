
require 'spec_helper'

module Locomotive
  module Plugins
    describe Registration do

      before(:each) do
        Locomotive::Plugins::SpecHelpers.before_each
      end

      it 'should register valid plugins' do
        Plugins.init_plugins do
          load 'my_plugin.rb'
        end

        Plugins.registered_plugins.count.should == 1
        Plugins.registered_plugins['my_plugin'].should == ::MyPlugin
      end

      it 'should return the plugin id which was used' do
        load 'my_plugin.rb'
        plugin_id = Plugins.register_plugin!(MyPlugin)
        plugin_id.should == 'my_plugin'
      end

      it 'should not register invalid plugins'

      it 'should use the underscored class name as the default id'

      it 'should allow a plugin to specify its own id'

      it 'should allow the Locomotive Plugin config to specify the id for a plugin'

      it 'should thow an exception if two plugins are registered under the same id'

    end
  end
end
