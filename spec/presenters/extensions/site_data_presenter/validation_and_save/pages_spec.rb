require 'spec_helper'

module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        describe 'pages' do

          let(:site) { FactoryGirl.create(:site) }

          let(:site_data) { ::Locomotive::SiteDataPresenter.new(site) }

          it 'should save the reference to the parent page' do
            params = {
              :pages => [
                new_page_grandchild_of_index_attributes,
                new_page_child_of_index_attributes,
                new_page_attributes
              ]
            }.with_indifferent_access

            site_data.build_models(params)
            site_data.insert.should be_true

            index = site.pages.where(:slug => 'index').first
            page = site.pages.where(:slug => 'new-page').first
            child = site.pages.where(:slug => 'child_of_index').first
            grandchild = site.pages.where(:slug => 'grandchild_of_index').first

            page.parent.should == index
            child.parent.should == index
            grandchild.parent.should == child
          end

          it 'should validate the uniqueness of the slug' do
            params = {
              :pages => [
                new_page_attributes,
                new_page_attributes,
                new_page_child_of_index_attributes,
                new_page_grandchild_of_index_attributes,
                new_page_grandchild_of_index_attributes
              ]
            }.with_indifferent_access

            site_data.build_models(params)
            site_data.insert.should be_false

            site_data.errors.should == {
              'pages' => {
                1 => {
                  :slug => [ 'is already taken' ]
                },
                4 => {
                  :slug => [ 'is already taken' ]
                }
              }
            }
          end

          it 'should validate the uniqueness of the slug against pages already in the database' do
            FactoryGirl.create(:page, :title => new_page_attributes[:title],
                              :slug => new_page_attributes[:slug],
                              :parent => site.pages.where(:slug => 'index').first,
                              :site => site)
            params = {
              :pages => [
                new_page_attributes
              ]
            }.with_indifferent_access

            site_data.build_models(params)
            site_data.insert.should be_false

            site_data.errors.should == {
              'pages' => {
                0 => {
                  :slug => [ 'is already taken' ]
                }
              }
            }
          end

          protected

          def new_page_attributes
            {
              :slug => 'new-page',
              :title => 'New page',
              :raw_template => 'New page template',
              :parent_fullpath => 'index'
            }
          end

          def new_page_child_of_index_attributes
            {
              :slug => 'child_of_index',
              :title => 'Child of Index',
              :raw_template => 'New page template',
              :parent_fullpath => 'index'
            }
          end

          def new_page_grandchild_of_index_attributes
            {
              :slug => 'grandchild_of_index',
              :title => 'Grandchild of Index',
              :raw_template => 'New page template',
              :parent_fullpath => 'child_of_index'
            }
          end

        end
      end
    end
  end
end
