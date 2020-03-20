class Announcement < ActiveRecord::Base
  STATUS = %w[draft active archived].freeze

  validates :title, presence: true

  validates :body, :image_url, :action, :url, :icon,
            presence: true, if: :active?
  validates :webview, inclusion: [true, false], allow_nil: false, if: :active?

  validates :status, inclusion: STATUS
  validates :image_url, format: { with: %r(\Ahttps?://\S+\z) }, allow_blank: true
  validates :url, format: { with: %r(\A(https?|mailto|entourage):\S+\z) }, allow_blank: true

  scope :ordered, -> { order(:position, :id) }

  STATUS.each do |status|
    scope status, -> { where(status: status) }

    define_method("#{status}?") do
      self.status == status
    end
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
