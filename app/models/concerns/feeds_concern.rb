module FeedsConcern
  extend ActiveSupport::Concern

  included do
    scope :before, -> (before){ where("created_at < ?", before) }
  end
end