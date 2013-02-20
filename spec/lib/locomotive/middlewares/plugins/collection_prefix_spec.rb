
require 'spec_helper'

module Locomotive
  module Middlewares
    module Plugins
      describe CollectionPrefix do

        let(:app) { stub(call: nil) }

        let(:site) do
          # Make sure the site we're using isn't the first one in the DB
          FactoryGirl.create(:site)
          FactoryGirl.create(:site, subdomain: 'my-subdomain')
        end

        it 'should fetch the correct site id' do
          middleware = CollectionPrefix.new(app)

          Locomotive.config.stubs(:multi_sites).returns(true)
          middleware.fetch_site_id(site.domains.first).should == site.id

          Locomotive.config.stubs(:multi_sites).returns(false)
          middleware.fetch_site_id(site.domains.first).should ==
            Locomotive::Site.first.id

          Locomotive::Site.first.should_not == site
        end

        it 'should get a nil site id for a subdomain which doesn\'t exist' do
          middleware = CollectionPrefix.new(app)

          Locomotive.config.stubs(:multi_sites).returns(true)
          middleware.fetch_site_id('unknown-subdomain').should be_nil
        end

      end
    end
  end
end
