class Category < ApplicationRecord

  validates :name, presence: true, uniqueness: true
  has_and_belongs_to_many :pois
  has_many :exclusive_pois

  def to_s
    name
  end
end
