class Neighborhood < ApplicationRecord
  include Interestable

  belongs_to :user

  has_many :join_requests, as: :joinable, dependent: :destroy
  has_many :members, through: :join_requests, source: :user

  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable, dependent: :destroy

  # # Fields
  # title
  # ethics
  # members
  # members_count
  # photo_url
  # interests
  # events
  # events_count
  # past_events_count
  # future_events_count
  # ongoing_events

  def members_count
    members.count
  end

  def past_events
    nil
  end

  def past_events_count
    nil
  end

  def future_events
    nil
  end

  def future_events_count
    nil
  end

  def has_ongoing_event
    nil
  end
end
