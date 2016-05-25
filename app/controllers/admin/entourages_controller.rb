module Admin
  class EntouragesController
    def index
      @entourages = Entourage.includes(:user).page(params[:page]).per(params[:per])
    end
  end
end