class HomeController < ApplicationController

  skip_before_filter :require_login

  def tours_map
    render layout: 'full_screen'
  end

  def latest_tours
    @latest_tours = Tour.order(created_at: :desc).limit(10)
  end
  
  def apps
    render layout: 'full_screen'
  end

end
