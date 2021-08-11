module UserServices
  class Unblock
    def self.run!
      User.blocked.where('unblock_at is not null and unblock_at < ?', Time.now).pluck(:id).each do |user_id|
        User.find(user_id).unblock! OpenStruct.new(id: nil), 'auto'
      end
    end
  end
end
