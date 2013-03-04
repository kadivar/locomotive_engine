
require 'spec_helper'

module Locomotive
  module Plugins
    describe RackAppPassthrough do

      let(:site) do
        # Make sure the site we're using isn't the first one in the DB
        FactoryGirl.create(:site)
        FactoryGirl.create(:site, subdomain: 'my-subdomain')
      end

      let(:passthrough) { RackAppPassthrough.new('plugin_id') }

      it 'should fetch the correct site' do
        Locomotive.config.stubs(:multi_sites).returns(true)
        passthrough.send(:fetch_site, site.domains.first).should == site

        Locomotive.config.stubs(:multi_sites).returns(false)
        passthrough.send(:fetch_site, site.domains.first).should ==
          Locomotive::Site.first

        Locomotive::Site.first.should_not == site
      end

      it 'should get a nil site for a subdomain which doesn\'t exist' do
        Locomotive.config.stubs(:multi_sites).returns(true)
        passthrough.send(:fetch_site, 'unknown-subdomain').should be_nil
      end

      it 'should get the prepared Rack app' do
        passthrough.stubs(:fetch_site).returns(site)

        plugin = RackPlugin.new
        plugin_id = plugin.class.default_plugin_id

        plugin_data = FactoryGirl.create(:plugin_data, plugin_id: plugin_id,
          enabled: true, site: site)

        env = {
          'action_dispatch.request.path_parameters' => {
            :plugin_id => plugin_id
          }
        }

        app = passthrough.send(:get_app, env)
        app.should == RackPlugin::RackApp

        plugin_data.enabled = false
        plugin_data.save!
        site.reload

        app = passthrough.send(:get_app, env)
        app.should be_nil
      end

      protected

      Locomotive::Plugins.init_plugins do
        class RackPlugin
          include Locomotive::Plugin

          def self.rack_app
            RackApp
          end

          class RackApp
            def self.call(env)
              [200, {}, []]
            end
          end
        end
      end

    end
  end
end
