module Locomotive
  module Api
    class SiteDataController < BaseController

      skip_load_and_authorize_resource

      def show
        @site_data = Locomotive::SiteDataPresenter.new(current_site, current_ability)
        respond_with(@site_data)
      end

      def create
        @site_data = Locomotive::SiteDataPresenter.new(current_site, current_ability)
        @site_data.create_models(params[:site_data])

        # Manually respond with the appropriate json
        # FIXME: currently assuming no errors occur
        respond_to do |format|
          format.json { render :json => @site_data }
        end
      end

    end

  end
end

