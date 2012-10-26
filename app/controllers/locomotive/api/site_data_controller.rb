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
        # FIXME shouldn't assign anything until after authorization
        @site_data = Locomotive::SiteDataPresenter.new(current_site,
          params[:site_data])
        @site_data.authorize!(current_ability, :create)

        # Manually respond with the appropriate json
        respond_to do |format|
          if @site_data.insert
            format.json { render :json => @site_data, :status => :created }
          else
            format.json { render :json => @site_data.errors, :status => :unprocessable_entity }
          end
        end
      end

      def mirror
        @site_data = Locomotive::SiteDataPresenter.all(current_site)
        @site_data.authorize!(current_ability, :destroy)
        @site_data.authorize!(current_ability, :create)
        @site_data.mirror(params[:site_data])

        respond_to do |format|
          if @site_data.insert
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
          if @site_data.update
            format.json { render :json => @site_data, :status => :created }
          else
            format.json { render :json => @site_data.errors, :status => :unprocessable_entity }
          end
        end
      end

      def destroy
        @site_data = Locomotive::SiteDataPresenter.find_from_ids(
          current_site, params[:site_data])
        @site_data.authorize!(current_ability, :destroy)
        @site_data.destroy_all

        respond_to do |format|
          format.json { head :no_content }
        end
      end

    end

  end
end

