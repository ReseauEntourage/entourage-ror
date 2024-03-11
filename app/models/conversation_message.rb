class ConversationMessage < ApplicationRecord
  belongs_to :messageable, polymorphic: true
  belongs_to :user
  belongs_to :full_object, polymorphic: true

  scope :ordered, -> { order(:created_at) }
  scope :with_content, -> { where("content <> ''") }

  def self.with_moderator_reads_for(user:)
    joins(%(
      left join moderator_reads on (
        moderator_reads.user_id = #{user.id} and
        moderator_reads.moderatable_id = conversation_messages.messageable_id and
        moderator_reads.moderatable_type = conversation_messages.messageable_type
      )
    ))
  end

  def deleted?
    status.to_sym == :deleted
  end

  # @param force true to bypass deletion
  def content force = false
    return "" if deleted? && !force

    self[:content]
  end
end
