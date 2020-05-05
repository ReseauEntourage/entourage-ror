class ModerationArea < ActiveRecord::Base
  belongs_to :moderator, class_name: :User
end
