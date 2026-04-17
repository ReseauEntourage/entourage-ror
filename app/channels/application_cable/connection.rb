module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def connect
      Rails.logger.info "ActionCable Connection established"
    end
  end
end
