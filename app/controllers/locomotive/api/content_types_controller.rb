module Locomotive
  module Api
    class ContentTypesController < BaseController

      load_and_authorize_resource :class => Locomotive::ContentType

      def index
        @content_types = current_site.content_types.order_by([[:name, :asc]])
        respond_with(@content_types)
      end

      def show
        @content_type = current_site.content_types.find(params[:id])
        respond_with @content_type
      end

      def create
        @content_type = current_site.content_types.new
        update_and_respond_with_presenter(@content_type, params[:content_type])
      end

      def update
        @content_type = current_site.content_types.find(params[:id])
        update_and_respond_with_presenter(@content_type, params[:content_type])
      end

      def destroy
        @content_type = current_site.content_types.find(params[:id])
        @content_type.destroy
        respond_with @content_type
      end

    end
  end
end
