class UserDenormJob
  include Sidekiq::Worker
  def perform(entourage_id:, user_id:)
    if entourage_id
      # recompute all users
      JoinRequest.select(:id, :user_id).where(joinable_type: 'Entourage', joinable_id: entourage_id).find_in_batches(batch_size: 10) do |join_requests|
        join_requests.map(&:user_id).each do |user_id|
          UserDenorm.find_or_create_by(user_id: user_id).recompute_and_save
        end
      end
    elsif user_id
      UserDenorm.find_or_create_by(user_id: user_id).recompute_and_save
    end
  end

  def self.perform_later(entourage_id:, user_id:)
    UserDenormJob.perform_async(entourage_id: entourage_id, user_id: user_id)
  end
end
