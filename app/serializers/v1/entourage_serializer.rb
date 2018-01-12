module V1
  class EntourageSerializer < ActiveModel::Serializer
    include V1::Myfeeds::LastMessage
    include V1::Entourages::Location

    attributes :id,
               :status,
               :title,
               :entourage_type,
               :display_category,
               :join_status,
               :number_of_unread_messages,
               :number_of_people,
               :created_at,
               :updated_at,
               :description,
               :share_url

    has_one :author
    has_one :location
    has_one :last_message

    def filter(keys)
      include_last_message? ? keys : keys - [:last_message]
    end

    def author
      return unless object.user
      entourage_author = object.user
      {
          id: entourage_author.id,
          display_name: entourage_author.first_name,
          avatar_url: UserServices::Avatar.new(user: entourage_author).thumbnail_url,
          partner: object.user.default_partner.nil? ? nil : V1::PartnerSerializer.new(object.user.default_partner, scope: {user: object.user}, root: false).as_json
      }
    end

    def join_status
      if current_join_request
        current_join_request.status
      else
        "not_requested"
      end
    end

    def number_of_unread_messages
      return nil unless current_join_request
      return object.chat_messages.count if current_join_request.last_message_read.nil?
      object.chat_messages.where("created_at > ?", current_join_request.last_message_read).count
    end

    def current_join_request
      #TODO : replace by sql request ?
      object.join_requests.select {|join_request| join_request.user_id == scope[:user]&.id}.first
    end

    def share_url
      return unless object.uuid_v2
      share_url_prefix = ENV['PUBLIC_SHARE_URL'] || 'http://entourage.social/entourages/'
      "#{share_url_prefix}#{object.uuid_v2}"
    end
  end
end
