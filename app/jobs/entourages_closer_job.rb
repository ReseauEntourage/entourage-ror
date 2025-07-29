require 'sidekiq/api'

# @todo RSPEC tests
class EntouragesCloserJob
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: :default

  def perform entourage_id, user_status
    Entourage.find(entourage_id).close_entourage_from_user_status! user_status
  end

  # ActiveJob interface
  def self.perform_later entourage_ids, user_status
    entourage_ids.each do |entourage_id|
      perform_async entourage_id, user_status
    end
  end
end
