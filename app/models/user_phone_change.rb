class UserPhoneChange < ApplicationRecord
  belongs_to :user
  belongs_to :admin, foreign_key: :admin_id, class_name: 'User', required: false

  def self.pending_user_ids
    UserPhoneChange.joins(
      'left outer join user_phone_changes joined on joined.user_id = user_phone_changes.user_id and user_phone_changes.id < joined.id'
    ).where('joined.id is null').where("user_phone_changes.kind = 'request'").pluck(:user_id)
  end
end
