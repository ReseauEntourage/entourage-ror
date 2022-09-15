class UserRecommandationObserver < ActiveRecord::Observer
  observe :user

  def after_update user
    return unless user.saved_change_to_last_sign_in_at?

    initiate_recommandations(user)
  end

  def initiate_recommandations user
    RecommandationServices::User.new(user).initiate
  end
end
