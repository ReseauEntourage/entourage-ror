class ChatMessage < ActiveRecord::Base
  include FeedsConcern

  belongs_to :messageable, polymorphic: true
  belongs_to :user

  validates :messageable_id, :messageable_type, :content, :user_id, presence: true

  scope :ordered, -> { order("created_at DESC") }
end
