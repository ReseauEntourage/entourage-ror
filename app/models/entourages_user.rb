class EntouragesUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :entourage

  validates_presence_of :user_id, :entourage_id, :status
  validates_uniqueness_of :entourage_id, {scope: [:user_id], message: "a déjà été ajouté"}
  validates_inclusion_of :status, in: ["pending", "accepted", "rejected"]
end
