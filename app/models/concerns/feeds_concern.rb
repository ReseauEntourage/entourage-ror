module FeedsConcern
  extend ActiveSupport::Concern

  included do
    scope :before, -> (before){ where("updated_at < ?", before) }
  end
end