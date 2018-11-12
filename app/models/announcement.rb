class Announcement
  include ActiveModel::Serializers::JSON

  ATTRIBUTES = [
    :id,
    :title,
    :body,
    :image_url,
    :action,
    :url,
    :icon_url,
    :author,
    :webview,
    :position
  ].freeze
  attr_accessor *ATTRIBUTES

  def initialize(attributes={})
    self.attributes = attributes
  end

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    Hash[ATTRIBUTES.map { |key| [key.to_s, send(key)] }]
  end

  def feed_object
    Feed.new(self)
  end

  class Feed
    def initialize(announcement)
      @feedable = announcement
    end

    attr_accessor :current_join_request,
                  :number_of_unread_messages,
                  :last_chat_message,
                  :last_join_request

    def feedable_type
      feedable.class.name
    end

    def feedable_id
      feedable.id
    end

    attr_reader :feedable
  end
end
