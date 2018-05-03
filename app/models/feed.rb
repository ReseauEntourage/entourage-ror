class Feed < ActiveRecord::Base
  include FeedsConcern
  reverse_geocoded_by :latitude, :longitude

  # https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/attributes.rb
  attribute :community, Community::Type.new

  belongs_to :user
  belongs_to :feedable, polymorphic: true
end