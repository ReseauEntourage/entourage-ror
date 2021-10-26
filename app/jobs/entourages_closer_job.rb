require 'sidekiq/api'

# @todo RSPEC tests
class EntouragesCloserJob
  include Sidekiq::Worker
  sidekiq_options :retry => true, queue: :default

  def perform entourage_id
    Entourage.find(entourage_id).update_attribute(:status, :closed)
  end

  # ActiveJob interface
  def self.perform_later entourage_ids
    entourage_ids.each do |entourage_id|
      perform_async entourage_id
    end
  end
end
