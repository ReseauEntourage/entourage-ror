module Experimental
  class SlackValidation
    attr_reader :id, :username

    def initialize id, username
      @id = id
      @username = username
    end

    def entourage_validation status
      record = Entourage.find(id)

      validation(record, status)
      payload(record, status)
    end

    def neighborhood_validation status
      record = Neighborhood.unscoped.find(id)

      validation(record, status)
      payload(record, status)
    end

    def validation record, status
      method = "set_#{record.class.name.underscore}_as_#{status}"
      raise unless respond_to?(method)

      send(method, record)
    end

    def payload record, status
      method = "payload_#{record.class.name.underscore}_as_#{status}"
      raise unless respond_to?(method)

      send(method, record)
    end

    # entourage
    def set_entourage_as_validate record
      record.update_attribute(:status, :open) unless record.status == :closed
      record.set_moderation_dates_and_save
    end

    def set_entourage_as_block record
      record.update_attribute(:status, :blacklisted) unless record.status == :suspended
      record.set_moderation_dates_and_save
    end

    def payload_entourage_as_validate record
      payload = Experimental::EntourageSlack.payload(record)
      payload[:attachments].first[:color] = :good
      payload[:attachments].last[:text] = "*:white_check_mark: <@#{username}> a validé cette action*"
      payload
    end

    def payload_entourage_as_block record
      payload = Experimental::EntourageSlack.payload(record)
      payload[:attachments].first[:color] = :danger
      payload[:attachments].last[:text] = "*:no_entry_sign: <@#{username}> a bloqué cette action*"
      payload
    end

    # neighborhood
    def set_neighborhood_as_validate record
      record.update_attribute(:status, :active) unless record.status == :closed
    end

    def set_neighborhood_as_block record
      record.update_attribute(:status, :blacklisted)
    end

    def payload_neighborhood_as_validate record
      payload = Experimental::NeighborhoodSlack.payload(record)
      payload[:attachments].first[:color] = :good
      payload[:attachments].last[:text] = "*:white_check_mark: <@#{username}> a validé ce groupe de voisinage*"
      payload
    end

    def payload_neighborhood_as_block record
      payload = Experimental::NeighborhoodSlack.payload(record)
      payload[:attachments].first[:color] = :danger
      payload[:attachments].last[:text] = "*:no_entry_sign: <@#{username}> a bloqué ce groupe de voisinage*"
      payload
    end
  end
end
