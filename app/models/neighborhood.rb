class Neighborhood < ApplicationRecord
  include Interestable

  belongs_to :user

  has_many :join_requests, as: :joinable, dependent: :destroy
  has_many :members, through: :join_requests, source: :user
  has_many :neighborhoods_entourages

  has_many :outings, -> { where(group_type: :outing) }, through: :neighborhoods_entourages, source: :entourage

  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable, dependent: :destroy

  validates_presence_of [:name, :latitude, :longitude]

  def members_count
    members.count
  end

  def past_outings
    outings.where("metadata->>'ends_at' < ?", Time.zone.now)
  end

  def past_outings_count
    past_outings.count
  end

  def future_outings
    outings.where("metadata->>'starts_at' > ?", Time.zone.now)
  end

  def future_outings_count
    future_outings.count
  end

  def ongoing_outings
    outings.where("metadata->>'starts_at' >= ?", Time.zone.now).where("metadata->>'ends_at' <= ?", Time.zone.now)
  end

  def has_ongoing_outing?
    ongoing_outings.any?
  end
end
