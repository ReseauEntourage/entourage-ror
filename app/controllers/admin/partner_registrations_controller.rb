module Admin
  class PartnerRegistrationsController < Admin::BaseController
    before_action :set_user, only: [:edit, :update]

    def index
      @params = params.permit([:status, q: [:postal_code_start, :postal_code_in_hors_zone]]).to_h

      @status = params[:status].presence&.to_sym
      @status = :all unless @status.in?([:pending])

      @users = User.where(goal: :organization)
        .joins(partner_join_requests: :partner)
        .joins(:addresses)

      @users = @users.in_area('dep_' + @params[:q][:postal_code_start]) if @params[:q] && @params[:q][:postal_code_start]
      @users = @users.in_area(:hors_zone) if @params[:q] && @params[:q][:postal_code_in_hors_zone]

      @users = @users.page(params[:page]).per(25)
    end

    def edit
    end

    def update
      @user.assign_attributes(user_params)

      if @user.save
        redirect_to edit_admin_partner_registration_path(@user), notice: "L'utilisateur a bien été mis à jour"
      else
        render :edit
      end
    end

    private

    def user_params
      params.require(:user).permit(:partner_id, :targeting_profile)
    end

    def set_user
      @user = User.find(params[:id])
    end
  end
end
