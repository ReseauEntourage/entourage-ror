module CommunityAdmin
  class SessionsController < BaseController
    skip_before_action :authenticate_user!, only: [:new, :create]

    def new
      if current_user
        redirect_to CommunityAdminService.after_sign_in_url(user: current_user)
      end
    end

    def create
      user = UserServices::UserAuthenticator.authenticate(
        community: community,
        phone: params[:phone],
        secret: params[:password],
        platform: :mobile # to allow for sms_code or full web password.
      )

      if user.nil?
        redirect_to new_community_admin_session_path(
          phone: params[:phone],
          error: :login_failure
        )
        return
      end

      unless CommunityAdminService.coordinator?(user)
        redirect_to new_community_admin_session_path(
          phone: params[:phone],
          error: :not_coordinator
        )
        return
      end

      sign_in(user)

      redirect_to CommunityAdminService.after_sign_in_url(
        user: user,
        continue: params[:continue]
      )
    end

    def destroy
      sign_out
      redirect_to community_admin_path
    end
  end
end
