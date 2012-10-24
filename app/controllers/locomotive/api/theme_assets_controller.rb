module Locomotive
  module Api
    class ThemeAssetsController < BaseController

      load_and_authorize_resource :class => Locomotive::ThemeAsset

      def index
        @theme_assets = current_site.theme_assets.all
        respond_with(@theme_assets)
      end

      def show
        @theme_asset = current_site.theme_assets.find(params[:id])
        respond_with @theme_asset
      end

      def create
        @theme_asset = current_site.theme_assets.new
        update_and_respond_with_presenter(@theme_asset, params[:theme_asset])
      end

      def update
        @theme_asset = current_site.theme_assets.find(params[:id])
        update_and_respond_with_presenter(@theme_asset, params[:theme_asset])
      end

      def destroy
        @theme_asset = current_site.theme_assets.find(params[:id])
        @theme_asset.destroy
        respond_with @theme_asset
      end

    end
  end
end
