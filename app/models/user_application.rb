class UserApplication < ActiveRecord::Base
  ANDROID="ANDROID"
  IOS="IOS"

  belongs_to :user

  validates :push_token, :device_os, :version, :user_id, :device_family, presence: true
  validates_uniqueness_of :version, {scope: [:user_id, :device_os]}
  validates_uniqueness_of :push_token
  validates_inclusion_of :device_family, in: [UserApplication::ANDROID, UserApplication::IOS]
end
