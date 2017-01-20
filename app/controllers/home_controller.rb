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
    redirect_to "https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection.html"
  end

  def cgu
  end
end
