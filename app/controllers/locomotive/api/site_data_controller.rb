module Locomotive
  module Api
    class SiteDataController < BaseController

      skip_load_and_authorize_resource

      def show
        @site_data = Locomotive::SiteDataPresenter.all(current_site)
        @site_data.authorize!(current_ability, :index)
        respond_with(@site_data)
      end

      def create
        # FIXME don't assign anything until after authorization
        @site_data = Locomotive::SiteDataPresenter.new(current_site,
          params[:site_data])
        @site_data.authorize!(current_ability, :create)

        # Manually respond with the appropriate json
        respond_to do |format|
          if @site_data.save
            format.json { render :json => @site_data, :status => :created }
          else
            format.json { render :json => @site_data.errors, :status => :unprocessable_entity }
          end
        end
      end

      def update
        @site_data = Locomotive::SiteDataPresenter.find_from_attributes(
          current_site, params[:site_data])
        @site_data.authorize!(current_ability, :update)
        @site_data.assign_attributes(params[:site_data])

        # Manually respond with the appropriate json
        respond_to do |format|
          if @site_data.save
            format.json { render :json => @site_data, :status => :created }
          else
            format.json { render :json => @site_data.errors, :status => :unprocessable_entity }
          end
        end
      end

    end

  end
end

