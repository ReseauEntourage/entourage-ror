module FeedUpdatedAt
  def self.update klass, id, value
    klass = klass.to_s.constantize unless klass.is_a?(Class)

    return unless klass == Entourage

    klass
      .where(id: id)
      .update_all([UPDATE_SQL, *[value] * TIMESTAMPS.count])
  end

  private

  TIMESTAMPS = [:updated_at, :feed_updated_at]

  def self.update_sql timestamps
    timestamps
      .map { |timestamp| "#{timestamp} = greatest(#{timestamp}, ?)" }
      .join(', ')
  end

  UPDATE_SQL = update_sql(TIMESTAMPS)
end
