class HomeController < ApplicationController

  skip_before_filter :require_login

  def tours_map
  end

end
