module Locomotive
  module Api
    class AccountsController < Api::BaseController

      load_and_authorize_resource :class => Locomotive::Account

      skip_load_and_authorize_resource :only => [ :show, :create ]

      def index
        @accounts = Locomotive::Account.all
        authorize! :index, @accounts
        respond_with(@accounts)
      end

      def show
        @account = Locomotive::Account.find(params[:id])
        authorize! :show, @account
        respond_with(@account)
      end

      def create
        @account = Locomotive::Account.new
        authorize! :create, @account
        update_and_respond_with_presenter(@account, params[:account])
      end

      def destroy
        @account = Locomotive::Account.find(params[:id])
        authorize! :destroy, @account
        @account.destroy
        respond_with(@account)
      end

      protected

      def load_account
        @account ||= load_accounts.find(params[:id])
      end

      def load_accounts
        @accounts ||= current_site.accounts
      end

    end

  end
end

