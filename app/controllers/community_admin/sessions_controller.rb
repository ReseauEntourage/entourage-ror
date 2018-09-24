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
        platform: :web
      )

      sign_in(user) if !user.nil?

      if current_user.nil?
        redirect_to new_community_admin_session_path(
          phone: params[:phone],
          error: :login_failure
        )
      else
        redirect_to CommunityAdminService.after_sign_in_url(
          user: user,
          continue: params[:continue]
        )
      end
    end

    def destroy
      sign_out
      redirect_to community_admin_path
    end
  end
end
