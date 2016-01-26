class EntouragesUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :entourage

  validates_presence_of :user_id, :entourage_id
end
