class HomeController < ApplicationController

  skip_before_filter :require_login

  def index
    redirect_to organization_dashboard_url
  end

  def apps
    render layout: 'full_screen'
  end

end
