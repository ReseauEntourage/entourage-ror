module V1
  class EntourageSerializer < ActiveModel::Serializer
    include V1::Myfeeds::LastMessage
    include V1::Entourages::Location

    attributes :id,
               :uuid,
               :status,
               :outcome,
               :title,
               :group_type,
               :public,
               :metadata,
               :entourage_type,
               :display_category,
               :postal_code,
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
        other_participants =
          if object.join_requests.loaded?
            User.where(id: object.join_requests.map(&:user_id) - [scope[:user]&.id])
          else
            object.members.where.not(id: scope[:user]&.id)
          end
        other_participant = other_participants.includes(:partner).first
        object.user = other_participant if other_participant

        object.title = UserPresenter.new(user: object.user).display_name
      end
    end

    def filter(keys)
      if scope[:sharing_selection]
        return [
          :id, :uuid,
          :title,
          :group_type, :entourage_type, :display_category,
          :author
        ]
      end

      keys.delete :last_message unless include_last_message?
      keys.delete :outcome unless object.has_outcome?
      keys
    end

    def uuid
      case object.group_type
      when 'action', 'conversation', 'outing', 'group'
        object.uuid_v2
      else
        object.uuid
      end
    end

    def group_type
      # good_waves cheat
      if object.group_type == 'group'
        'action'
      else
        object.group_type
      end
    end

    def author
      return unless object.user
      entourage_author = object.user
      # TODO(partner)
      {
          id: entourage_author.id,
          display_name: UserPresenter.new(user: object.user).display_name,
          avatar_url: UserServices::Avatar.new(user: entourage_author).thumbnail_url,
          partner: object.user.partner.nil? ? nil : V1::PartnerSerializer.new(object.user.partner, scope: {user: object.user}, root: false).as_json
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
      if current_join_request.nil?
        nil
      elsif scope.key?(:number_of_unread_messages)
        scope[:number_of_unread_messages]
      elsif current_join_request.status != 'accepted'
        0
      elsif current_join_request.last_message_read.nil?
        object.chat_messages.count
      else
        object.chat_messages.where("created_at > ?", current_join_request.last_message_read).count
      end
    end

    def updated_at
      res = [object.updated_at, object.feed_updated_at].compact.max
    end

    def current_join_request
      if scope[:user].nil?
        nil
      elsif scope.key?(:current_join_request)
        return scope[:current_join_request]
      elsif object.join_requests.loaded?
        object.join_requests.select {|join_request| join_request.user_id == scope[:user].id}.first
      else
        JoinRequest.where(user_id: scope[:user].id, joinable: object).first
      end
    end

    def metadata
      object.metadata.except(:$id)
    end
  end
end
