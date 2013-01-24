
require 'spec_helper'

module Locomotive
  module Plugins
    describe RackAppPassthrough do

      let(:site) do
        # Make sure the site we're using isn't the first one in the DB
        FactoryGirl.create(:site)
        FactoryGirl.create(:site, subdomain: 'my-subdomain')
      end

      it 'should fetch the correct site' do
        Locomotive.config.stubs(:multi_sites).returns(true)
        RackAppPassthrough.fetch_site(site.domains.first).should == site

        Locomotive.config.stubs(:multi_sites).returns(false)
        RackAppPassthrough.fetch_site(site.domains.first).should ==
          Locomotive::Site.first

        Locomotive::Site.first.should_not == site
      end

      it 'should get a nil site for a subdomain which doesn\'t exist' do
        Locomotive.config.stubs(:multi_sites).returns(true)
        RackAppPassthrough.fetch_site('unknown-subdomain').should be_nil
      end

    end
  end
end
