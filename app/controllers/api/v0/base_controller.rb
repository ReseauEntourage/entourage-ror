module Api
  module V0
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      before_filter :authenticate_user!

      def current_user
        @current_user ||= User.find_by_token params[:token]
      end

      def authenticate_user!
        render 'unauthorized', status: :unauthorized unless current_user
      end
    end
  end
end
