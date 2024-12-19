module Admin
  class ActionsController < Admin::BaseController
    layout 'admin_large'

    def index
      @params = params.permit([:area, :search]).to_h
      @area = params[:area].presence&.to_sym || :all

      @actions = Action.includes([:user, :openai_request, matchings: :match])
      @actions = @actions.search_by(params[:search]) if params[:search].present?
      @actions = @actions.with_moderation_area(@area.to_s) if @area && @area != :all
      @actions = @actions.page(page).per(per)
    end

    private

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
