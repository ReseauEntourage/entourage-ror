class Announcement
  include ActiveModel::Serializers::JSON

  ATTRIBUTES = [
    :id,
    :title,
    :body,
    :action,
    :url,
    :icon_url,
    :author
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
    attr_reader :feedable
  end
end
