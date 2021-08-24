module Admin
  class PartnerRegistrationsController < Admin::BaseController
    def index
      @params = params.permit([:status, q: [:postal_code_start, :postal_code_in_hors_zone]]).to_h

      @status = params[:status].presence&.to_sym
      @status = :all unless @status.in?([:pending])

      @users = User.where(goal: :organization)
        .joins(partner_join_requests: :partner)
        .joins(:addresses)

      @users = @users.in_area("dep_" + @params[:q][:postal_code_start]) if @params[:q] && @params[:q][:postal_code_start]
      @users = @users.in_area(:hors_zone) if @params[:q] && @params[:q][:postal_code_in_hors_zone]

      @users = @users.page(params[:page]).per(25)
    end
  end
end
