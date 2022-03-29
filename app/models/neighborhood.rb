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

  alias_attribute :title, :name

  # behaviors

  # EC-94: list neighborhoods
  # EC-95: join neighborhood
  # EC-117: leave neighborhood
  # EC-95: show neighborhood
  # EC-99: find neighborhood
  # EC-100: create neighborhood
  # EC-118: add photo to neighborhood
  # EC-101: update neighborhood
  # EC-104: add localization to neighborhood
  # EC-104: add localization to neighborhood
  # main: post comment in neighborhood conversation
  # main: create outing in neighborhood
  # main: signal neighborhood
  # main: signal a user in neighborhood (ethics)

  # EC-82 [groupe] modérer la création d'un groupe
  # EC-83 [groupe] être notifié sur la création d'un groupe
  # EC-84 [groupe] détecter groupes similaires
  # EC-85 [groupe] détecter groupes abusifs : détection
  # EC-86 [groupe] détecter groupes abusifs : design interface
  # EC-88 [groupe] détecter groupes abusifs : notification
  # EC-89 [modé] détecter mots abusifs sur contenu publié : détection
  # EC-90 [modé] détecter mots abusifs sur contenu publié : design interface
  # EC-91 [modé] détecter mots abusifs sur contenu publié : notification
  # EC-92 [groupe] éditer les infos d'un groupe

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

  def group_type
    'neighborhood'
  end

  def group_type_config
    {
      'message_types' => ['text', 'share'],
      'roles' => ['admin', 'member']
    }
  end
end
