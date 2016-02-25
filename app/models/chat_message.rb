class ChatMessage < ActiveRecord::Base
  belongs_to :messageable, polymorphic: true
  belongs_to :user

  validates :messageable_id, :messageable_type, :content, :user_id, presence: true
end
