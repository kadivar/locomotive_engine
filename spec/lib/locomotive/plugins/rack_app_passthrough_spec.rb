
require 'spec_helper'

module Locomotive
  module Plugins
    describe RackAppPassthrough do

      let(:site) do
        # Make sure the site we're using isn't the first one in the DB
        FactoryGirl.create(:site)
        FactoryGirl.create(:site, subdomain: 'my-subdomain')
      end

      after(:each) do
        # Reset config
        Locomotive.config = nil
      end

      it 'should fetch the correct site' do
        Locomotive.config.multi_sites = true
        RackAppPassthrough.fetch_site(site.domains.first).should == site

        Locomotive.config.multi_sites = false
        RackAppPassthrough.fetch_site(site.domains.first).should ==
          Locomotive::Site.first

        Locomotive::Site.first.should_not == site
      end

      it 'should get a nil site for a subdomain which doesn\'t exist' do
        Locomotive.config.multi_sites = true
        RackAppPassthrough.fetch_site('unknown-subdomain').should be_nil
      end

    end
  end
end
