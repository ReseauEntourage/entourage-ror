class Entourage < ActiveRecord::Base
  belongs_to :user
  has_many :join_requests, as: :joinable
  has_many :members, through: :join_requests, source: :user
  reverse_geocoded_by :latitude, :longitude
  has_many :chat_messages, as: :messageable
  has_many :entourage_invitations, as: :invitable

  validates_presence_of :status, :title, :entourage_type, :user_id, :latitude, :longitude, :number_of_people
  validates_inclusion_of :status, in: ['open', 'closed']
  validates_inclusion_of :entourage_type, in: ['ask_for_help', 'contribution']
end
