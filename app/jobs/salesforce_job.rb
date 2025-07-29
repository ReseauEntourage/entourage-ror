require 'sidekiq/api'

class SalesforceJob
  include Sidekiq::Worker

  sidekiq_options retry: false, queue: :salesforce

  def perform(class_name, id, verb)
    instance = class_name.constantize.find(id)

    return perform_destroy(instance) if verb == 'destroy'
    return perform_upsert(instance) if ['create', 'upsert'].include?(verb)

    perform_default(instance, verb)
  end

  def perform_destroy instance
    instance.sf.destroy
    instance.update_attribute(:salesforce_id, nil)
  end

  def perform_upsert instance
    return unless salesforce_id = instance.sf.upsert

    instance.update_attribute(:salesforce_id, salesforce_id)
  end

  def perform_default instance, verb
    instance.sf.send(verb)
  end

  # ActiveJob interface
  def self.perform_later(instance, verb)
    perform_async(instance.class.name, instance.id, verb.to_s)
  end
end
