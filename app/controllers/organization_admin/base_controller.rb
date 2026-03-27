require 'layout_options'

module OrganizationAdmin
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :authenticate_user!
    before_action :ensure_org_member!

    skip_before_action :authenticate_user!, :ensure_org_member!, only: :auth

    helper_method :current_user, :community

    include LayoutOptions
    layout 'organization_admin'

    def home
      groups = current_user.partner.groups
        .where(status: :open) # suspended ?

      @actions = groups.where(group_type: :action).order(created_at: :desc).to_a
      @events = groups.where(group_type: :outing)
        .where("metadata->>'ends_at' >= ?", Time.zone.now)
        .order(Arel.sql("metadata->>'starts_at'"))
        .to_a
    end

    def auth
      user = UserServices::UserAuthenticator.authenticate_with_token(
        auth_token: params[:auth_token],
        platform: UserApplication::WEB
      )

      if user.nil? || user.partner.nil?
        return redirect_to ENV['WEBSITE_URL'] + '/app?org_admin_login_required'
      end

      message = params[:message] if params[:message].in?(['webapp_logout'])

      if message == 'webapp_logout'
        sign_out
        return redirect_to ENV['WEBSITE_URL'] + '/app'
      else
        sign_in user
        redirect_to organization_admin_path
      end
    end

    def webapp_redirect
      auth_token = UserServices::UserAuthenticator.auth_token(current_user, expires_in: 5.seconds)
      redirect_to ENV['WEBSITE_URL'] + '/app?auth=' + auth_token
    end

    def authenticate_user!
      if current_user.nil?
        return redirect_to ENV['WEBSITE_URL'] + '/app?org_admin_login_required'
      end
    end

    def sign_out
      session[:org_admin_user_id] = nil
      cookies.delete(:user_id)
      @current_user = nil
    end

    def sign_in user
      session[:org_admin_user_id] = user.id
      cookies.encrypted[:user_id] = user.id
      @current_user = nil
    end

    def current_user
      return @current_user if @current_user != nil
      return nil if session[:org_admin_user_id].nil?

      @current_user = community.users.find_by(id: session[:org_admin_user_id])

      sign_out if @current_user.nil?

      @current_user
    end

    def community
      @community ||= begin
        $server_community
      end
    end

    def ensure_org_member!
      unless current_user.partner_id.present?
        render text: "Cette action nécessite d'être membre d'une organisation", status: :unauthorized
      end
    end

    def ensure_org_admin!
      unless current_user.partner_admin?
        render text: "Cette action nécessite d'être administrateur de l'organisation", status: :unauthorized
      end
    end
  end
end
