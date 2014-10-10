class UsersController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def validation
    @user = User.find_by_email(params[:email])
  end
end
