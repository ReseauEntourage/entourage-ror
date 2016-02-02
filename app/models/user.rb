class User < ActiveRecord::Base

  validates_presence_of [:phone, :sms_code, :token]
  validates_uniqueness_of [:email, :token, :phone]
  validate :validate_phone!
  validates_format_of :email, with: /@/, unless: "email.nil?"
  validates_presence_of [:first_name, :last_name, :organization, :email], if: Proc.new { |u| u.pro? }
  validates_associated :organization, if: Proc.new { |u| u.pro? }

  has_many :tours
  has_many :encounters, through: :tours
  has_many :login_histories
  has_many :entourages
  has_many :entourages_users
  has_many :entourage_participations, through: :entourages_users, source: :entourage
  has_many :tours_users
  has_many :tour_participations, through: :tours_users, source: :tour
  belongs_to :organization
  has_and_belongs_to_many :coordinated_organizations, -> { uniq }, class_name: "Organization", join_table: "coordination"

  enum device_type: [ :android, :ios ]

  delegate :name, :description, to: :organization, prefix: true

  scope :pro, -> { where(user_type: "pro") }

  def validate_phone!
    unless PhoneValidator.new(phone: self.phone).valid?
      errors.add(:phone, "devrait être au format +33... ou 06...")
    end
  end

  #Force all phone number to be inserted in DB in "+33" format
  def phone=(new_phone)
    super(Phone::PhoneBuilder.new(phone: new_phone).format)
  end

  def to_s
    "#{id} - #{first_name} #{last_name}"
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end

  def sms_code=(another_sms_code)
    #Hashing slows down tests a lot
    if Rails.env.test? && ENV["DISABLE_CRYPT"]=="TRUE"
      return super(another_sms_code)
    end

    another_sms_code = BCrypt::Password.create(another_sms_code) unless (another_sms_code.nil?)
    super(another_sms_code)
  end

  def pro?
    user_type=="pro"
  end

  def public?
    user_type=="public"
  end
end