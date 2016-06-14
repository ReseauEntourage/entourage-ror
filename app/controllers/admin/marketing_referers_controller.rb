module Admin
  class MarketingReferersController < Admin::BaseController
    def index
      @marketing_referers = MarketingReferer.page(params[:page]).per(25)
    end
  end
end