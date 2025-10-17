module UserServices
  class Unblock
    # temporary_block period is 1.month (User::TEMPORARY_BLOCK_PERIOD)
    # we use last_sign_in_at to reduce psql scan
    def self.run!
      User
        .status_is(:blocked)
        .where("last_sign_in_at >= NOW() - INTERVAL '3 months'")
        .where('unblock_at is not null and date(unblock_at) = ?', Date.today)
        .pluck(:id)
        .each do |user_id|
        SlackServices::UnblockUser.new(user_id: user_id).notify
      end
    end
  end
end
