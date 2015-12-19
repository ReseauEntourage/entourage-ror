class HomeController < ApplicationController
  def apps
    render layout: 'full_screen'
  end

  def store_redirection
    render layout: 'full_screen'
  end
end
