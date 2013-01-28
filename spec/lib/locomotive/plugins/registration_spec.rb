
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

      it 'should not register invalid plugins' do
        # No init_plugins block
        Plugins.registered_plugins.count.should == 0
      end

      it 'should use the underscored class name as the default id' do
        Plugins.init_plugins do
          load 'my_plugin.rb'
        end

        Plugins.registered_plugins.count.should == 1
        Plugins.registered_plugins['my_plugin'].should == ::MyPlugin
      end

      it 'should allow a plugin to specify its own id' do
        # Remove custom id to ensure it gets detected on load
        load 'my_other_plugin.rb'
        def MyOtherPlugin.default_plugin_id
          'wrong_id'
        end

        Plugins.init_plugins do
          load 'my_other_plugin.rb'
        end

        Plugins.registered_plugins.count.should == 1
        Plugins.registered_plugins['custom_plugin_id'].should == ::MyOtherPlugin
      end

      it 'should throw an exception if two plugins are registered under the same id' do
        lambda do
          Plugins.init_plugins do
            load 'my_plugin.rb'
            load 'my_other_plugin.rb'
            def MyOtherPlugin.default_plugin_id
              'my_plugin'
            end
          end
        end.should raise_error
      end

      # TODO
      # it 'should allow the Locomotive Plugin config to specify the id for a plugin'

    end
  end
end
