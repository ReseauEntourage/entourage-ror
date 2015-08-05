class User < ActiveRecord::Base

  has_many :encounters

  validates :email, presence: true, uniqueness: true

  enum device_type: [ :android ]

  after_create :set_token

  def set_token
    self.update_attribute(:token, Digest::MD5.hexdigest(self.id.to_s + self.created_at.to_s))
  end

  def to_s
    "#{id} - #{first_name} #{last_name}"
  end

end
