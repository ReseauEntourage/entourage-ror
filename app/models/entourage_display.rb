class EntourageDisplay < ActiveRecord::Base
  belongs_to :entourage
  belongs_to :user
end
