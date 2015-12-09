class HomeController < ApplicationController
  skip_before_filter :require_login

  def apps
    render layout: 'full_screen'
  end

end
