class NewChatMessageNotifierJob < ActiveJob::Base
  def perform(user_id)
    user = User.find
  end
end