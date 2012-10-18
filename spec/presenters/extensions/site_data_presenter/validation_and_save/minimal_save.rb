require 'spec_helper'

module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        describe MinimalSave do

          let(:site) { Locomotive::Site.first || FactoryGirl.create(:site) }

          let(:site_data) { ::Locomotive::SiteDataPresenter.new(site) }

          context 'pages' do

            it 'should only save page slugs and site_id' do
              params = {
                :pages => [
                  new_page_attributes
                ]
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              page = site.pages.where(:slug => 'new-page').first

              page.slug.should == 'new-page'
              page.raw_template.should_not == 'New page template'
            end

            it 'should generate the slug from the title' do
              params = {
                :pages => [
                  new_page_attributes_with_title
                ]
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              page = site.pages.where(:slug => 'new-page').first

              page.slug.should == 'new-page'
              page.title.should == 'New page'
            end

            it 'should validate the uniqueness and presence of the slug' do
              params = {
                :pages => [
                  new_page_attributes,
                  new_page_attributes
                ]
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_false

              site_data.errors.should == {
                'errors' => {
                  'pages' => {
                    1 => {
                      :slug => [ 'is already taken' ]
                    }
                  }
                }
              }
            end

          end

          protected

          def new_page_attributes
            {
              :slug => 'new-page',
              :raw_template => 'New page template'
            }
          end

          def new_page_attributes_with_title
            attrs = new_page_attributes
            attrs.delete(:slug)
            attrs[:title] = 'New page'
            attrs
          end

        end
      end
    end
  end
end
