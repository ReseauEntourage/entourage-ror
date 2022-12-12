module V1
  class EntourageSerializer < ActiveModel::Serializer
    include AmsLazyRelationships::Core

    include V1::Myfeeds::LastMessage
    include V1::Entourages::Location
    include V1::Entourages::Blockers

    attributes :id,
               :uuid,
               :title,
               :group_type,
               :entourage_type,
               :display_category

    attribute :status, unless: :sharing_selection?
    attribute :public, unless: :sharing_selection?
    attribute :metadata, unless: :sharing_selection?
    attribute :postal_code, unless: :sharing_selection?
    attribute :join_status, unless: :sharing_selection?
    attribute :number_of_unread_messages, unless: :sharing_selection?
    attribute :number_of_people, unless: :sharing_selection?
    attribute :created_at, unless: :sharing_selection?
    attribute :updated_at, unless: :sharing_selection?
    attribute :description, unless: :sharing_selection?
    attribute :share_url, unless: :sharing_selection?
    attribute :image_url, unless: :sharing_selection?
    attribute :online, unless: :sharing_selection?
    attribute :event_url, unless: :sharing_selection?
    attribute :display_report_prompt, unless: :sharing_selection?

    attribute :outcome, if: :outcome?
    attribute :blockers, if: :private_conversation?

    has_one :author
    has_one :location
    has_one :last_message, if: :last_message?

    lazy_relationship :last_chat_message
    lazy_relationship :chat_messages_count
    lazy_relationship :chat_messages
    lazy_relationship :join_requests

    def initialize(*)
      super

      # try to put other user as author if conversation
      # and user's name as title
      if object.group_type == 'conversation'
        other_participant = object.members.find do |member|
          member.id != scope[:user]&.id
        end

        # weird fix on "find a null conversations by list uuid" spec
        # fix when conversation id is nil; is this should ever been the case? Maybe pfp related
        other_participant = User.where(id: object.join_requests.map(&:user_id) - [scope[:user]&.id]).first unless other_participant

        object.user = other_participant if other_participant
        object.title = UserPresenter.new(user: object.user).display_name
      end
    end

    def sharing_selection?
      scope[:sharing_selection]
    end

    def outcome?
      return false if sharing_selection?
      object.has_outcome?
    end

    def last_message?
      return false if sharing_selection?
      include_last_message?
    end

    def private_conversation?
      object.conversation?
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
      return unless entourage_author = object.user
      partner = entourage_author.partner

      {
        id: entourage_author.id,
        display_name: UserPresenter.new(user: entourage_author).display_name,
        avatar_url: UserServices::Avatar.new(user: entourage_author).thumbnail_url,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: { user: scope[:user], following: true }, root: false).as_json,
        partner_role_title: entourage_author.partner_role_title.presence
      }
    end

    def join_status
      current_join_request&.simplified_status || "not_requested"
    end

    def number_of_unread_messages
      return 0 if current_join_request.nil?
      return scope[:number_of_unread_messages] if scope.key?(:number_of_unread_messages)
      return lazy_chat_messages_count&.count || 0 if current_join_request.last_message_read.nil?

      lazy_chat_messages.select do |chat_message|
        chat_message.created_at > current_join_request.last_message_read
      end.count
    end

    def updated_at
      res = [object.updated_at, object.feed_updated_at].compact.max
    end

    def current_join_request
      @current_join_request ||= begin
        if scope[:user].nil?
          nil
        elsif scope.key?(:current_join_request)
          scope[:current_join_request]
        else
          # @fixme performance issue: we instanciate all records but we need only one
          lazy_join_requests.select do |join_request|
            join_request.user_id == scope[:user].id
          end.first
        end
      end
    end

    def metadata
      object.metadata_with_image_paths.except(:$id)
    end

    def display_report_prompt
      return false if current_join_request.nil?
      current_join_request.report_prompt_status == 'display'
    end

    def display_category
      object.display_category || display_category_from_section
    end

    private

    def display_category_from_section
      return unless object.action?

      action = object.contribution? ? object.becomes(Contribution) : object.becomes(Solicitation)

      ActionServices::Mapper.display_category_from_section(action.section)
    end
  end
end
