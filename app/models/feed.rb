class Feed < ActiveRecord::Base
  include FeedsConcern
  reverse_geocoded_by :latitude, :longitude

  belongs_to :user
  belongs_to :feedable, polymorphic: true
end