class User < ActiveRecord::Base

  validates_presence_of [:first_name, :last_name, :email, :phone]
  validates_uniqueness_of [:email]
  validates_format_of :phone, with: /\A\+33[0-9]{9}\Z/, on: :create
  validates_format_of :email, with: Devise.email_regexp
  has_many :tours
  has_many :encounters, through: :tours

  enum device_type: [ :android ]

  after_create :set_token, :set_sms_code

  def set_token
    self.update_attribute(:token, Digest::MD5.hexdigest(self.id.to_s + self.created_at.to_s))
  end
  
  def set_sms_code
    self.update_attribute(:sms_code, '%06i' % rand(1000000))
  end

  def to_s
    "#{id} - #{first_name} #{last_name}"
  end

end