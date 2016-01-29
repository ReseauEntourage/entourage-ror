class ToursUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :tour

  validates_presence_of :user_id, :tour_id, :status
  validates_uniqueness_of :tour_id, {scope: [:user_id], message: "a déjà été ajouté"}
  validates_inclusion_of :status, in: ["pending", "accepted", "rejected"]

  def accepted?
    status=="accepted"
  end

  def reject!
    self.update(status: "rejected")
  end
end
