require 'spec_helper'

module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        describe MinimalSave do

          let(:site) { Locomotive::Site.first || FactoryGirl.create(:site) }

          let(:site_data) { ::Locomotive::SiteDataPresenter.new(site) }

          context 'pages' do

            it 'should only save page slug, title and site_id' do
              params = {
                :pages => [
                  new_page_attributes
                ]
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              page = site.pages.where(:slug => 'new-page').first

              page.slug.should == 'new-page'
              page.title.should == 'New page'
              page.raw_template.should_not == new_page_attributes[:raw_template]
            end

            it 'should generate the slug from the title' do
              params = {
                :pages => [
                  new_page_attributes_without_slug
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

          context 'content_types' do

            it 'should only save content_type slug, name and site_id' do
              params = {
                :content_types => [
                  new_content_type_attributes
                ]
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              content_type = site.content_types.where(:slug => 'projects').first

              content_type.slug.should == 'projects'
              content_type.name.should == 'Projects'
              content_type.description.should_not == new_content_type_attributes[:description]
            end

            it 'should generate the slug from the name' do
              params = {
                :content_types => [
                  new_content_type_attributes_without_slug
                ]
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              content_type = site.content_types.where(:slug => 'projects').first

              content_type.slug.should == 'projects'
              content_type.name.should == 'Projects'
            end

            it 'should validate the uniqueness of the slug' do
              params = {
                :content_types => [
                  new_content_type_attributes,
                  new_content_type_attributes
                ]
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_false

              site_data.errors.should == {
                'errors' => {
                  'content_types' => {
                    1 => {
                      :slug => [ 'is already taken' ]
                    }
                  }
                }
              }
            end

          end

          context 'content_entries' do

            before(:each) do
              create_projects_content_type!
            end

            it 'should only save content_entry slug, name and site_id' do
              params = {
                :content_entries => {
                  :projects => [
                    new_project_attributes
                  ]
                }
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              content_type = site.content_types.where(:slug => 'projects').first
              project = content_type.entries.where(:_slug => 'project-1').first

              project._slug.should == 'project-1'
              project.name.should == 'Project 1'
              project.description.should_not == new_project_attributes[:description]
            end

            it 'should generate the slug from the label field' do
              params = {
                :content_entries => {
                  :projects => [
                    new_project_attributes_without_slug
                  ]
                }
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              content_type = site.content_types.where(:slug => 'projects').first
              project = content_type.entries.where(:_slug => 'project-1').first

              project._slug.should == 'project-1'
              project.name.should == 'Project 1'
              project.description.should_not == new_project_attributes[:description]
            end

            it 'should generate a unique slug' do
              params = {
                :content_entries => {
                  :projects => [
                    new_project_attributes,
                    new_project_attributes
                  ]
                }
              }.with_indifferent_access
              site_data.build_models(params)
              site_data.send(:minimal_save_all).should be_true

              content_type = site.content_types.where(:slug => 'projects').first

              content_type.entries[0]._slug.should == 'project-1'
              content_type.entries[1]._slug.should == 'project-2'
            end

          end

          protected

          ## Page data ##

          def new_page_attributes
            {
              :slug => 'new-page',
              :title => 'New page',
              :raw_template => 'New page template'
            }
          end

          def new_page_attributes_without_slug
            attrs = new_page_attributes
            attrs.delete(:slug)
            attrs
          end

          ## Content type data ##

          def new_content_type_attributes
            {
              :slug => 'projects',
              :name => 'Projects',
              :description => 'Projects that the company does'
            }
          end

          def new_content_type_attributes_without_slug
            attrs = new_content_type_attributes
            attrs.delete(:slug)
            attrs
          end

          ## Content entry data ##

          def create_projects_content_type!
            content_type = FactoryGirl.build(:content_type, :name => 'Projects')
            content_type.entries_custom_fields.build(:label => 'Name', :type => 'string')
            content_type.entries_custom_fields.build(:label => 'Description', :type => 'text')
            content_type.save!
          end

          def new_project_attributes
            {
              :slug => 'project-1',
              :name => 'Project 1',
              :description => 'The first project ever'
            }
          end

          def new_project_attributes_without_slug
            attrs = new_project_attributes
            attrs.delete(:_slug)
            attrs
          end

        end
      end
    end
  end
end
