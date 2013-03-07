
require 'spec_helper'

module Locomotive
  module Plugins
    describe Registration do

      it 'should register valid plugins' do
        unregister_plugin('my_plugin')

        Plugins.registered_plugins['my_plugin'].should == nil
        Plugins.init_plugins do
          load_plugin 'my_plugin.rb', false
        end
        Plugins.registered_plugins['my_plugin'].should == ::MyPlugin
      end

      it 'should return the plugin id which was used' do
        unregister_plugin('my_plugin')
        plugin_id = Plugins.register_plugin!(MyPlugin)
        plugin_id.should == 'my_plugin'
      end

      it 'should not register invalid plugins' do
        unregister_plugin('my_plugin')

        # No init_plugins block
        Plugins.registered_plugins['my_plugin'].should == nil
        load_plugin 'my_plugin.rb', false
        Plugins.registered_plugins['my_plugin'].should == nil

        # Re-register
        Plugins.init_plugins do
          load_plugin 'my_plugin.rb'
        end
      end

      it 'should use the underscored class name as the default id' do
        Plugins.registered_plugins['my_plugin'].should == ::MyPlugin
      end

      it 'should allow a plugin to specify its own id' do
        Plugins.registered_plugins['custom_plugin_id'].should == ::MyOtherPlugin
      end

      it 'should throw an exception if two plugins are registered under the same id' do
        lambda do
          Plugins.init_plugins do
            load_plugin 'my_plugin.rb', true
            MyOtherPlugin.stubs(:default_plugin_id).returns('my_plugin')
            plugin_id = Plugins.register_plugin!(MyOtherPlugin)
          end
        end.should raise_error
      end

      # TODO
      # it 'should allow the Locomotive Plugin config to specify the id for a plugin'

      protected

      %w{load_plugin unregister_plugin}.each do |meth|
        define_method(meth) do |*args|
          Locomotive::Plugins::SpecHelpers.public_send(meth, *args)
        end
      end

    end
  end
end
