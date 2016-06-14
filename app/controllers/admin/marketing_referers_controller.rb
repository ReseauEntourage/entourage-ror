module Admin
  class MarketingReferersController < Admin::BaseController
    before_action :set_marketing_referer, only: [:edit, :update]

    def index
      @marketing_referers = MarketingReferer.page(params[:page]).per(25)
    end

    def edit
    end

    def new
      @marketing_referer = MarketingReferer.new
    end

    def create
      @marketing_referer = MarketingReferer.new(marketing_referer_params)
      if @marketing_referer.save
        redirect_to admin_marketing_referers_path, notice: "marketing_referer créé"
      else
        render :new
      end
    end

    def update
      if @marketing_referer.update(marketing_referer_params)
        flash[:notice] = "marketing_referer mis à jour"
      end
      render :edit
    end

    private
    def marketing_referer_params
      params.require(:marketing_referer).permit(:name)
    end

    def set_marketing_referer
      @marketing_referer = MarketingReferer.find(params[:id])
    end
  end
end