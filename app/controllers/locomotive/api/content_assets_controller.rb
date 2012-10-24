module Locomotive
  module Api
    class ContentAssetsController < BaseController

      load_and_authorize_resource :class => Locomotive::ContentAsset

      def index
        @content_assets = current_site.content_assets
        respond_with(@content_assets)
      end

      def show
        @content_asset = current_site.content_assets.find(params[:id])
        respond_with(@content_asset)
      end

      def create
        @content_asset = current_site.content_assets.new
        update_and_respond_with_presenter(@content_asset, params[:content_asset])
      end

      def update
        @content_asset = current_site.content_assets.find(params[:id])
        update_and_respond_with_presenter(@content_asset, params[:content_asset])
      end

      def destroy
        @content_asset = current_site.content_assets.find(params[:id])
        @content_asset.destroy
        respond_with @content_asset
      end

    end
  end
end
