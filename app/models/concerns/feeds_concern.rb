module FeedsConcern
  extend ActiveSupport::Concern

  included do
    scope :before, -> (before){ where("#{table_name}.updated_at < ?", before) }
  end
end