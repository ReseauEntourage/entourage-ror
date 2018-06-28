class HomeController < ApplicationController
  before_action :authenticate_user!, only: [:index]
  layout 'full_screen'

  def index
    if current_user.pro?
      redirect_to dashboard_organizations_path
    else
      redirect_to edit_public_user_user_path("me")
    end
  end

  def apps
  end

  def store_redirection
    case $server_community
    when 'entourage'
      redirect_to "https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection.html"
    when 'pfp'
      redirect_to "https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection_pfp.html"
    else
      raise AbstractController::ActionNotFound
    end
  end

  def cgu
  end
end
