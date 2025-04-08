module Mentionable
  extend ActiveSupport::Concern

  # remove html tags from text
  def self.no_html content
    return content unless content.is_a?(String)
    return content if content !~ /<[^>]+>/

    document = Nokogiri::HTML(content)
    document.css('img').each { |node| node.remove }
    document.css('a').each { |node| node.replace(node.text) }
    document.css('br').each { |node| node.replace("\n") }
    document.text.strip
  end

  # remove html tags from every text value
  def self.none_html! hash
    return unless hash.present?

    hash.each do |key, value|
      hash[key] = no_html(value)
    end

    hash
  end

  # remove html tags from text except for a.href and br
  def self.filter_html_tags(content, allowed_tags = %w[a br])
    return content unless content.is_a?(String)
    return content if content !~ /<[^>]+>/

    document = Nokogiri::HTML.fragment(content)

    document.traverse do |node|
      next unless node.element?
      next if allowed_tags.include?(node.name)

      if node.xpath('.//*').any? { |child| allowed_tags.include?(child.name) }
        node.replace(node.children)
      else
        node.replace(node.text)
      end
    end

    document.to_html
  end

  MentionsStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @instance = instance
    end

    def no_html
      Mentionable.no_html(@instance.content)
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

    def extract_user_ids_or_uuids
      user_links = fragments.css('a[href]').select { |a| a['href'].include?('app/users') }

      user_links.map do |a|
        a['href'][%r{app/users/([^/]+)}, 1]
      end
    end
  end

  def mentions
    @mentions ||= MentionsStruct.new(instance: self)
  end
end
