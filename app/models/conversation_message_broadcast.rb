require 'experimental/jsonb_set'

class ConversationMessageBroadcast < ActiveRecord::Base
  belongs_to :moderation_area

  validates_presence_of :moderation_area_id, :goal, :content, :title

  def name
    if moderation_area
      "#{title} (#{moderation_area.departement}, #{goal})"
    else
      title
    end
  end

  def archived?
    !!archived_at
  end

  def users
    return 0 unless valid?

    User.joins(:addresses).where('users.goal': goal, 'users.deleted': false).where(["addresses.country = 'FR' AND left(addresses.postal_code, 2) = ?", moderation_area.departement])
  end
end
