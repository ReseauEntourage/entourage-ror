module V1
  class EntourageSerializer < ActiveModel::Serializer
    include V1::Myfeeds::LastMessage
    include V1::Entourages::Location

    attributes :id,
               :uuid,
               :status,
               :title,
               :group_type,
               :entourage_type,
               :display_category,
               :join_status,
               :number_of_unread_messages,
               :number_of_people,
               :created_at,
               :updated_at,
               :description,
               :share_url

    has_one :author, serializer: ActiveModel::DefaultSerializer
    has_one :location, serializer: ActiveModel::DefaultSerializer
    has_one :last_message, serializer: ActiveModel::DefaultSerializer

    def initialize(*)
      super

      # try to put other user as author if conversation
      # and user's name as title
      if object.group_type == 'conversation'
        participant_ids =
          if object.join_requests.loaded?
            object.join_requests.map(&:user_id)
          else
            object.join_requests.pluck(:user_id)
          end
        other_user_id = participant_ids.find { |i| i != object.user_id }
        object.user_id = other_user_id if other_user_id

        object.title = UserPresenter.new(user: object.user).display_name
      end
    end

    def filter(keys)
      include_last_message? ? keys : keys - [:last_message]
    end

    def uuid
      case object.group_type
      when 'action', 'conversation'
        object.uuid_v2
      else
        object.uuid
      end
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
