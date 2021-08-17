class UserBlockObserver < ActiveRecord::Observer
  observe :user

  def after_update user
    if user.saved_change_to_validation_status? && user.blocked?
      close_entourages! user
      block_notifications! user
    end
  end

  def close_entourages! user
    Entourage.where(user_id: user.id, status: :open).update_all(status: :closed)
  end

  def block_notifications! user
  end
end
