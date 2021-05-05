class Announcement < ApplicationRecord
  STATUS = %w[draft active archived].freeze

  validates :title, presence: true

  validates :body, :image_url, :action, :url, :icon, :areas, :user_goals,
            presence: true, if: :active?
  validates :webview, inclusion: [true, false], allow_nil: false, if: :active?

  validates :status, inclusion: STATUS
  validates :image_url, format: { with: %r(\Ahttps?://\S+\z) }, allow_blank: true
  validates :image_portrait_url, format: { with: %r(\Ahttps?://\S+\z) }, allow_blank: true
  validates :url, format: { with: %r(\A(https?|mailto|entourage):\S+\z) }, allow_blank: true

  scope :ordered, -> { order(:position, :id) }
  scope :for_areas, -> (area_slugs) { where("areas ?| array[%s]" % area_slugs.map { |a| ApplicationRecord.connection.quote(a) }.join(',')) }
  scope :for_user_goal, -> (user_goal) { where("user_goals ? %s" % ApplicationRecord.connection.quote(user_goal)) }

  STATUS.each do |status|
    scope status, -> { where(status: status) }

    define_method("#{status}?") do
      self.status == status
    end
  end

  attribute :areas,      :jsonb_set
  attribute :user_goals, :jsonb_set

  before_validation do
    areas.reject!(&:blank?)
    user_goals.reject!(&:blank?)
  end

  def category= category
    if category.present?
      super category
    else
      self[:category] = nil
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
