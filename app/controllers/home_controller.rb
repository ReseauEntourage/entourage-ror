class HomeController < ApplicationController
  layout 'full_screen'

  def apps
  end

  def store_redirection
    redirect_to "https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection.html"
  end

  def cgu
  end
end
