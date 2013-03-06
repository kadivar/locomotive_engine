
require 'spec_helper'

module Locomotive
  module Middlewares
    describe Plugins do

      let(:app) { stub(call: nil) }

      let(:site) do
        # Make sure the site we're using isn't the first one in the DB
        FactoryGirl.create(:site)
        FactoryGirl.create(:site, subdomain: 'my-subdomain')
      end

      it 'should store the mountpoint host' do
        called = false
        middleware = Plugins.new(Proc.new do |env|
          called = true
          Plugins.mountpoint_host.should == 'http://www.example.com:3000'
        end)

        middleware.call(default_env)
        called.should be_true
      end

      it 'should fetch the correct site' do
        middleware = Plugins.new(app)
        middleware.stubs(:request).returns(stub(host: site.domains.first))

        Locomotive.config.stubs(:multi_sites).returns(true)
        middleware.send(:fetch_site).should == site

        Locomotive.config.stubs(:multi_sites).returns(false)
        middleware.send(:fetch_site).should == Locomotive::Site.first

        Locomotive::Site.first.should_not == site
      end

      it 'should get a nil site for a subdomain which doesn\'t exist' do
        middleware = Plugins.new(app)
        middleware.stubs(:request).returns(stub(host: 'unknown-subdomain'))

        Locomotive.config.stubs(:multi_sites).returns(true)
        middleware.send(:fetch_site).should be_nil
      end

      protected

      def default_env
        {
          'SERVER_NAME' => 'www.example.com',
          'SERVER_PORT' => '3000',
          'rack.url_scheme' => 'http'
        }
      end

    end
  end
end
