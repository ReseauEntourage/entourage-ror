class User < ActiveRecord::Base

  validates_presence_of [:first_name, :last_name, :email, :phone, :organization]
  validates_uniqueness_of [:email]
  validates_format_of :phone, with: /\A\+33[0-9]{9}\Z/
  validates_format_of :email, with: Devise.email_regexp
  has_many :tours
  has_many :encounters, through: :tours
  belongs_to :organization
  has_and_belongs_to_many :coordinated_organizations, -> { uniq }, class_name: "Organization", join_table: "coordination"

  enum device_type: [ :android, :ios ]

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
  
  def full_name
    "#{first_name} #{last_name}"
  end

end