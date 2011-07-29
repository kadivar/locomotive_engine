require 'spec_helper'

describe "Internationalization" do


  before :each do
    @page = Factory.build(:page)
    @site = Factory.build(:site)
    content_type = Factory.build(:content_type)
    content_type.content_custom_fields.build :label => 'anything', :kind => 'string'
    content_type.content_custom_fields.build :label => 'published_at', :kind => 'date'
    @content = content_type.contents.build({
      :meta_keywords => 'Libidinous, Angsty',
      :meta_description => "Quite the combination.",
      :published_at => Date.today })
  end

  it 'should return the previously defined field' do
    EditableElement.any_instance.stubs(:content).returns("test string")
    @element = @page.editable_elements.create(:slug => 'test')
    @page.stubs(:raw_template).returns("{% content test %}")
    template = Liquid::Template.parse(@page.raw_template)
    text = template.render!(liquid_context(:page => @page))
    text.should match /test string/
  end

  def liquid_context(options = {})
    ::Liquid::Context.new({}, {},
    {
      :page => options[:page]
    }, true)
  end

  describe 'meta_description' do
    subject { render_template('{{ content.meta_description }}') }
    it { should == @content.meta_description }
  end


  describe "locale specific rendering" do
    before(:each) do
      @assigns = {
        'somevar' => 'english default',
        'somevar_fr' => 'french',
      }
    end

    it 'changes assigns by locale -- default' do
      render_template('{{ somevar }}', @assigns).should == "english default"
    end

    it 'changes assigns by locale -- french' do
      render_template('{{ somevar }}', @assigns, {:locale => :fr}).should == "french"
    end

    #it ''
  end
  def render_template(template = '', assignsi = {}, environments = {})
    assigns = { 'content' => @content, 'today' => Date.today }.merge(assignsi)
    Liquid::Template.parse(template).render(::Liquid::Context.new(environments, assigns, { :site => @site }))
  end


end