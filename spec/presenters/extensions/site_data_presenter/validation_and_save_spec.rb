require 'spec_helper'

module Locomotive
  module Extensions
    module SiteDataPresenter
      describe ValidationAndSave do

        let(:site) { Locomotive::Site.first || FactoryGirl.create(:site) }

        let(:site_data) { ::Locomotive::SiteDataPresenter.new(site) }

        it 'should minimally save content types and content entries together' do
          params = {
            :content_types => [
              {
                :name => 'Employees',
                :entries_custom_fields => [
                  {
                    :label => 'Name',
                    :type => 'string'
                  }
                ]
              }
            ],
            :content_entries => {
              :employees => [
                {
                  :name => 'John Smith'
                }
              ]
            }
          }.with_indifferent_access

          site_data.build_models(params)
          site_data.insert.should be_true

          content_type = site.content_types.where(:slug => 'employees').first

          content_type.entries_custom_fields[0].name.should == 'name'
          content_type.entries[0]._label.should == 'John Smith'
        end

        it 'should fail gracefully on content_entries when its content_type fails' do
          params = {
            :content_types => [
              {
                :name => 'Employees',
                :entries_custom_fields => []
              }
            ],
            :content_entries => {
              :employees => [
                {
                  :name => 'John Smith'
                }
              ]
            }
          }.with_indifferent_access

          site_data.build_models(params)
          site_data.insert.should be_false

          site_data.errors.should == {
            'content_types' => {
              0 => {
                :entries_custom_fields => [ 'At least, one custom field is required' ]
              }
            },
            'content_entries' => {
              'employees' => [ 'content type does not exist' ]
            }
          }
        end


      end
    end
  end
end
