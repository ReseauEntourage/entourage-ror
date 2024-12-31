module Admin
  class OpenaiRequestsController < Admin::BaseController
    layout 'admin_large'

    before_action :set_openai_request, only: [:show]

    def index
      @params = params.permit(:module_type)
      @module_type = params[:module_type] || :matching

      @openai_requests = OpenaiRequest.preload(:instance)
        .where(module_type: @module_type)
        .order(updated_at: :desc)
        .page(page)
        .per(per)
    end

    def show
    end

    private

    def set_openai_request
      @openai_request = OpenaiRequest.find(params[:id])
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
