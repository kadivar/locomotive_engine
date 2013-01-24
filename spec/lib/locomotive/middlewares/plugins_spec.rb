
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

      after(:each) do
        # Reset config
        Locomotive.config = nil
      end

      it 'should fetch the correct site id' do
        middleware = Plugins.new(app)

        Locomotive.config.multi_sites = true
        middleware.fetch_site_id(site.domains.first).should == site.id

        Locomotive.config.multi_sites = false
        middleware.fetch_site_id(site.domains.first).should ==
          Locomotive::Site.first.id

        Locomotive::Site.first.should_not == site
      end

      it 'should get a nil site id for a subdomain which doesn\'t exist' do
        middleware = Plugins.new(app)

        Locomotive.config.multi_sites = true
        middleware.fetch_site_id('unknown-subdomain').should be_nil
      end

    end
  end
end
