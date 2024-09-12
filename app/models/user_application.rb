class UserApplication < ApplicationRecord
  ANDROID="ANDROID"
  IOS="IOS"
  WEB="WEB"

  belongs_to :user

  validates :push_token, :device_os, :version, :user_id, :device_family, presence: true
  validates_uniqueness_of :push_token, unless: :skip_uniqueness_validation_of_push_token?
  validates_inclusion_of :device_family, in: [UserApplication::ANDROID, UserApplication::IOS, UserApplication::WEB]

  def skip_uniqueness_validation_of_push_token!
    @skip_uniqueness_validation_of_push_token = true
  end

  def skip_uniqueness_validation_of_push_token?
    @skip_uniqueness_validation_of_push_token == true
  end

  def android?
    device_family == UserApplication::ANDROID
  end

  def ios?
    device_family == UserApplication::IOS
  end
end
