require 'experimental/jsonb_set'

class ConversationMessageBroadcast < ActiveRecord::Base
  validates_presence_of :area, :goal, :content, :title

  scope :archived, -> { where('archived_at != NULL') }
  scope :not_archived, -> { where(archived_at: nil) }

  def name
    if moderation_area
      "#{title} (#{area.departement}, #{goal})"
    else
      title
    end
  end

  def archived?
    !!archived_at
  end

  def user_ids
    users.select('users.id').map(&:id)
  end

  def users
    return 0 unless valid?

    users = User.joins(:addresses).where('users.goal': goal, 'users.deleted': false)

    if area.to_sym == :sans_zone
      users = users.where(["addresses.id IS NULL"])
    elsif area.to_sym == :hors_zone
      users = users.where(["addresses.country != 'FR' OR addresses.postal_code IS NULL"])
    else
      users = users.where(["addresses.country = 'FR' AND left(addresses.postal_code, 2) = ?", ModerationArea.departement(area)])
    end

    users.group('users.id')
  end

  # def succeeded(user, recipient)
  # end

  # def failed(user, recipient)
  # end
end
