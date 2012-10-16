require 'spec_helper'

module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        describe ContentEntries do

          let(:site) { Locomotive::Site.first || FactoryGirl.create(:site) }

          let(:site_data) { ::Locomotive::SiteDataPresenter.new(site) }

          let(:projects_content_type) do
            projects = FactoryGirl.build(:content_type, :name => 'Projects')
            projects.entries_custom_fields.build(
              :label => 'Title', :type => 'string')
            projects.save!
            projects
          end

          let(:employees_content_type) do
            employees = FactoryGirl.build(:content_type, :name => 'Employees')
            employees.entries_custom_fields.build(
              :label => 'Name', :type => 'string')
            employees.save!
            employees
          end

          before(:each) do
            setup_projects_employees_relationship
          end

          it 'should set up relationships between content entries' do
            params = {
              :content_entries => {
                :projects => [
                  {
                    :title => 'Website',
                    :employees => [ 'Joe', 'Bob' ]
                  },
                  {
                    :title => 'E-commerce App',
                    :employees => [ 'Joe' ]
                  }
                ],
                :employees => [
                  {
                    :name => 'Joe'
                  },
                  {
                    :name => 'Bob'
                  }
                ]
              }
            }.with_indifferent_access

            site_data.build_models(params)

            site_data.save.should be_true

            site.reload
            projects = site.content_types.where(:slug => 'projects').first.entries
            employees = site.content_types.where(:slug => 'employees').first.entries

            projects.count.should == 2
            employees.count.should == 2

            website = projects.where(:title => 'Website').first
            ecommerce = projects.where(:title => 'E-commerce App').first
            joe = employees.where(:name => 'Joe').first
            bob = employees.where(:name => 'Bob').first

            # Check to make sure the relationships are there
            website.employees.should include(joe)
            website.employees.should include(bob)
            ecommerce.employees.should include (joe)

            bob.projects.should include(website)
            joe.projects.should include(website)
            joe.projects.should include(ecommerce)
          end

          protected

          def setup_projects_employees_relationship
            projects_class = projects_content_type.klass_with_custom_fields(:entries)
            employees_class = employees_content_type.klass_with_custom_fields(:entries)

            projects_content_type.entries_custom_fields.build(
              :label => 'Employees', :type => 'many_to_many',
              :class_name => employees_class.to_s)
            projects_content_type.save!

            employees_content_type.entries_custom_fields.build(
              :label => 'Projects', :type => 'many_to_many',
              :class_name => projects_class.to_s, :inverse_of => 'employees')
            employees_content_type.save!

            f = projects_content_type.entries_custom_fields.last
            f.inverse_of = 'projects'
            projects_content_type.save!
          end

        end
      end
    end
  end
end
