require 'spec_helper'

describe Locomotive::Liquid::Drops::ContentTypes do

  before(:each) do
    @site = FactoryGirl.build(:site)
    @content_type = FactoryGirl.build(:content_type, :slug=>'things', :site => @site)
    @things = Locomotive::Liquid::Drops::ContentTypes.new()
  end


  context 'from remote source' do
    
    before(:each) do
      @content_type.from_remote_source =true;
      @content_type.remote_source_url = 'http://www.fake.fake';
      @content_type.save!
      return_val =  Array.new
      for i in 0..5
        return_val << {'id' => i}
      end
      response = mock('response', :code => 200, :underscore_keys => return_val)
      Locomotive::Httparty::Webservice.stubs(:get).returns(response)
    end
    
    
    it 'loads an external url' do
      template = "{% for thing in models.things %}{{thing.id}}{% endfor %}"
      render(template, {'models' => @things}, {}, {:site =>@site}).should == "012345"
    end

  end


  context 'from remote source on current site' do
    
    before(:each) do
      @content_type.from_remote_source =true;
      @content_type.remote_source_url = 'http://www.fake.fake';
      @content_type.save!
      return_val =  Array.new
      for i in 0..5
        return_val << {'id' => i}
      end
      Locomotive::Site.stubs(:match_domain).returns([1])
      Locomotive::Liquid::Drops::ContentTypes.stubs(:get_page_from_local_site).returns(return_val)
      
    end
    
    
    it 'loads from a source on this site' do
      template = "{% for thing in models.things %}{{thing.id}}{% endfor %}"
      render(template, {'models' => @things}, {}, {:site =>@site}).should == "012345"
    end

  end





  def render(template, assigns = {}, scopes = {}, registers = [])
    liquid_context = ::Liquid::Context.new(assigns, scopes, registers)

    output = ::Liquid::Template.parse(template).render(liquid_context)
    output.gsub(/\n\s{0,}/, '')
  end
end
