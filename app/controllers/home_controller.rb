class HomeController < ApplicationController

  skip_before_filter :require_login

  def tours_map
  end

  def latest_tours
    @latest_tours = Tour.order(created_at: :desc).limit(10)
  end

end
