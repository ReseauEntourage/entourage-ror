module Admin
  class EntouragesController < Admin::BaseController
    def index
      @entourages = Entourage.includes(:user).page(params[:page]).per(params[:per]).order("created_at DESC")
    end
  end
end