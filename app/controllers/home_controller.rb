class HomeController < ApplicationController
  before_action :authenticate_user!, only: [:index]
  layout 'full_screen'

  def index
    redirect_to edit_public_user_user_path('me')
  end

  def apps
  end

  def store_redirection
    url = 'https://s3-eu-west-1.amazonaws.com/entourage-ressources/store_redirection.html'

    # @fixme which params should be permitted?
    query_string = params.permit([:action, :controller]).except(:action, :controller).to_query
    url = "#{url}?#{query_string}" if query_string.present?
    redirect_to url, status: 301
  end

  def cgu
  end
end
