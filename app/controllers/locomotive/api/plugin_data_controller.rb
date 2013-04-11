module Locomotive
  module Api
    class PluginDataController < Api::BaseController

      #load_and_authorize_resource class: Locomotive::PluginData,
      #  through: :current_site, except: :index

      before_filter :load_and_authorize_plugin_data

      def index
        respond_with(@plugin_data)
      end

      def show
        respond_with(@plugin_data)
      end

      def update
        @plugin_data.from_presenter(params[:plugin_data])
        @plugin_data.save
        respond_with @plugin_data, location: main_app.url_for(action: 'show')
      end

      protected

      def load_and_authorize_plugin_data
        case params[:action]
        when 'index'
          @plugin_data = current_site.all_plugin_data.select do |plugin_data|
            can?(:read, plugin_data)
          end
        when 'show'
          @plugin_data = current_site.plugin_data.find(params[:id])
          authorize! :show, @plugin_data
        when 'update'
          @plugin_data = current_site.plugin_data.find(params[:id])
          authorize! :update, @plugin_data if params[:plugin_data][:enabled]
          authorize! :configure, @plugin_data if params[:plugin_data][:config]
        end
      end

    end
  end
end

