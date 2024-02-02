require 'sidekiq/api'

class SalesforceJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :salesforce

  def perform(user_id, verb)
    user = User.find(user_id)

    return perform_destroy(user) if verb == :destroy
    return perform_upsert(user) if [:create, :upsert].include?(verb)

    perform_default(user, verb)
  end

  def perform_destroy user
    user.sf.destroy
    user.update_attribute(:salesforce_id, nil)
  end

  def perform_upsert user
    user.sf.upsert

    return unless salesforce_id = user.sf.upsert

    user.update_attribute(:salesforce_id, salesforce_id)
  end

  def perform_default user, verb
    user.sf.send(verb)
  end

  # ActiveJob interface
  def self.perform_later(user_id, verb)
    perform_async(user_id, verb)
  end
end
