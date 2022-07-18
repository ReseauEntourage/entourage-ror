class Contribution < Entourage
  default_scope { where(group_type: :action, entourage_type: :contribution).order(feed_updated_at: :desc) }
end
