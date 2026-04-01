class RefreshEngagementLevelsJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW CONCURRENTLY engagement_levels"
    )
  end
end
