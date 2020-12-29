require 'experimental/jsonb_set'

class ConversationMessageBroadcast < ActiveRecord::Base
  validates_presence_of :area, :goal, :content, :title

  def name
    if moderation_area
      "#{title} (#{area.departement}, #{goal})"
    else
      title
    end
  end

  def status= status
    if status == :archived
      self['archived_at'] = Time.now
    end
    super(status)
  end

  def archived?
    !!archived_at
  end

  def draft?
    status&.to_sym == :draft
  end

  def sending?
    status&.to_sym == :sending
  end

  def user_ids
    users.select('users.id').map(&:id)
  end

  def users
    return [] unless valid?

    User.where('users.goal': goal, 'users.deleted': false).in_area(area).group('users.id')
  end

  # def succeeded(user, recipient)
  # end

  def clone
    ConversationMessageBroadcast.new(
      area: area,
      content: content,
      goal: goal,
      title: title
    )
  end
end
