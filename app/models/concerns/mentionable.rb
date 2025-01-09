module Mentionable
  extend ActiveSupport::Concern

  included do
    after_create :has_mentions!, if: :has_mentions?
  end

  MentionsStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def no_html
      document = Nokogiri::HTML(@instance.content)
      document.css('img').each { |node| node.remove }
      document.css('a').each { |node| node.replace(node.text) }
      document.text.strip
    end

    def fragments
      @fragments ||= Nokogiri::HTML.fragment(@instance.content)
    end

    def contains_html?
      fragments.children.any? { |node| node.element? }
    end

    def contains_anchor_with_href?
      fragments.css('a[href]').any?
    end

    def contains_user_link?
      fragments.css('a[href]').any? { |a| a['href'].include?('app/users') }
    end

    def extract_user_uuid
      user_links = fragments.css('a[href]').select { |a| a['href'].include?('app/users') }

      user_links.map do |a|
        a['href'][%r{app/users/([^/]+)}, 1]
      end
    end
  end

  def mentions
    @mentions ||= MentionsStruct.new(instance: self)
  end

  def has_mentions?
    mentions.extract_user_uuid.any?
  end

  def has_mentions!
    return unless has_mentions?

    # @todo perform in a job
    PushNotificationTrigger.new(self, :mention, Hash.new).run
  end
end
