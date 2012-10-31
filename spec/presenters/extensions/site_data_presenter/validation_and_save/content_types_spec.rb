require 'spec_helper'

module Locomotive
  module Extensions
    module SiteDataPresenter
      module ValidationAndSave
        describe ContentTypes do

          let(:site) { FactoryGirl.create(:site) }

          let(:site_data) { ::Locomotive::SiteDataPresenter.new(site) }

          let(:projects_content_type) do
            {
              :name => 'Projects',
              :entries_custom_fields => [
                {
                  :label => 'Name',
                  :type => 'string'
                },
                {
                  :label => 'Employees',
                  :type => 'many_to_many',
                  :content_type_slug => 'employees',
                  :inverse_of => 'projects'
                }
              ]
            }
          end

          let(:employees_content_type) do
            {
              :name => 'Employees',
              :entries_custom_fields => [
                {
                  :label => 'Name',
                  :type => 'string'
                },
                {
                  :label => 'Projects',
                  :type => 'many_to_many',
                  :content_type_slug => 'projects',
                  :inverse_of => 'employees'
                }
              ]
            }
          end

          it 'should set up relationships between content types' do
            params = {
              :content_types => [
                projects_content_type,
                employees_content_type
              ]
            }.with_indifferent_access

            site_data.build_models(params)
            site_data.insert.should be_true

            site.content_types.count.should == 2
            projects_type = site.content_types.where(:slug => 'projects').first
            employees_type = site.content_types.where(:slug => 'employees').first

            # Check to make sure the relationship fields are linked up
            projects_to_employees = projects_type.entries_custom_fields.where(
              :name => 'employees').first
            employees_to_projects = employees_type.entries_custom_fields.where(
              :name => 'projects').first

            projects_to_employees.class_name.should ==
              employees_type.klass_with_custom_fields(:entries).to_s
            employees_to_projects.class_name.should ==
              projects_type.klass_with_custom_fields(:entries).to_s
          end

          it 'should not save content types with invalid relationship fields' do
            params = {
              :content_types => [
                projects_content_type
              ]
            }.with_indifferent_access

            site_data.build_models(params)

            site_data.insert.should be_false

            site.reload

            site.content_types.count.should == 0

            custom_field_errors = site_data.errors.with_indifferent_access[
              :content_types][0][:entries_custom_fields]
            custom_field_errors.should include('invalid content_type_slug "employees"')
          end

        end
      end
    end
  end
end
