module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def connect
      puts "\n[ActionCable] New connection established"
    end
  end
end
