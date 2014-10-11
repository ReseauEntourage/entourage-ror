class User < ActiveRecord::Base

  validates :email, presence: true, uniqueness: true

  has_many :encounters

  def to_s
    "#{id} - #{first_name} #{last_name}"
  end

end
