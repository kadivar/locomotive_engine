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

        # Manually respond with the appropriate json
        respond_to do |format|
          if @site_data.create_models(params[:site_data])
            puts 'Controller: success!'
            format.json { render :json => @site_data, :status => :created }
          else
            puts 'Controller: failure!'
            format.json { render :json => @site_data.errors, :status => :unprocessable_entity }
          end
        end
      end

    end

  end
end

