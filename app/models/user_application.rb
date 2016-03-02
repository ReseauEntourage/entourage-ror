class UserApplication < ActiveRecord::Base
  belongs_to :user

  validates :push_token, :device_os, :version, :user_id, presence: true
  validates_uniqueness_of :version, {scope: [:user_id, :device_os]}
end
