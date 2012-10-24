module Locomotive
  module Api
    class ContentEntriesController < BaseController

      before_filter :set_content_type

      def index
        @content_entries = @content_type.ordered_entries
        respond_with @content_entries
      end

      def show
        @content_entry = @content_type.entries.any_of({ :_id => params[:id] }, { :_slug => params[:id] }).first
        respond_with @content_entry, :status => @content_entry ? :ok : :not_found
      end

      def create
        @content_entry = @content_type.entries.build
        update_and_respond_with_presenter(@content_entry, params[:content_entry], "/content_types/#{@content_type.slug}/entries/#{@content_entry.id}")
      end

      def update
        @content_entry = @content_type.entries.find(params[:id])
        update_and_respond_with_presenter(@content_entry, params[:content_entry], "/content_types/#{@content_type.slug}/entries/#{@content_entry.id}")
      end

      def destroy
        @content_entry = @content_type.entries.find(params[:id])
        @content_entry.destroy
        respond_with @content_entry, :location => main_app.locomotive_api_content_entries_url(@content_type.slug)
      end

      protected

      def set_content_type
        @content_type ||= current_site.content_types.where(:slug => params[:slug]).first
      end

    end
  end
end
