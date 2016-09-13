class Feed < ActiveRecord::Base
  include FeedsConcern

  belongs_to :user
  belongs_to :feedable, polymorphic: true
end