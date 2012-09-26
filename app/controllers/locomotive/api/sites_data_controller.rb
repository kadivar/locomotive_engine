module Locomotive
  module Api
    class SiteDataController < BaseController

      skip_load_and_authorize_resource

      def show
        @site_data = Locomotive::SiteDataPresenter.new(current_site, current_ability)
        respond_with(@site_data.as_json)
      end

    end

  end
end

