module UserServices
  class Unblock
    def self.run!
      User.status_is(:blocked).where('unblock_at is not null and unblock_at < ?', Time.now).pluck(:id).each do |user_id|
        SlackServices::UnblockUser.new(user_id: user_id).notify
      end
    end
  end
end
