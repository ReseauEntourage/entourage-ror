module ModeratorReadable
  extend ActiveSupport::Concern

  included do
    has_many :moderator_reads, as: :moderatable, dependent: :destroy
  end

  def moderator_read_for user:
    moderator_reads.where(user_id: user.id).first
  end

  def no_moderator_read_for user:
    moderator_read_for(user: user).nil?
  end

  def moderator_has_unread_content user:
    moderator_read = moderator_read_for(user: user)
    return true unless moderator_read && moderator_read.read_at

    no_moderator_read_for(user: user) || unread_chat_message_after(read_at: moderator_read.read_at)
  end

  def unread_chat_message_after read_at:
    chat_messages.ordered.with_content.where('created_at > ?', read_at).any?
  end

  class_methods do
    def with_moderator_reads_for user:
      joins(%(
        left join moderator_reads on (
          moderator_reads.user_id = #{user.id} and
          moderator_reads.moderatable_id = #{table_name}.id and
          moderator_reads.moderatable_type = '#{self.base_class.name}'
        )
      ))
    end
  end
end
