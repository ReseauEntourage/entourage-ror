module Admin
  class ConversationsController < Admin::BaseController
    def index
      @user = User.find_by email: 'guillaume@entourage.social', community: :entourage

      @conversations = Entourage
        .where(group_type: :conversation)
        .joins(:join_requests)
        .merge(@user.join_requests.accepted)
        .joins("join last_chat_messages on last_chat_messages.entourage_id = entourages.id")
        .order("last_chat_messages.created_at desc")
        .select(%(
          entourages.*,
          last_chat_messages.id as last_message_id,
          last_message_read is null or last_message_read < last_chat_messages.created_at as unread
        ))
        .page(params[:page])
        .per(50)

      @last_message = Hash[ChatMessage.where(id: @conversations.map(&:last_message_id)).map { |m| [m.messageable_id, m] }]

      @recipient_ids = JoinRequest.accepted.where(joinable_type: :Entourage, joinable_id: @conversations.map(&:id)).where.not(user_id: @user.id).pluck(:joinable_id, :user_id).group_by(&:first).each { |_, a| a.replace a.map(&:last) }

      @users = Hash[(User.where(id: @recipient_ids.values.map{ |a| a.first(3) }.flatten + @last_message.values.map(&:user_id)).uniq).map { |u| [u.id, u] }]

      render layout: 'admin_large'
    end
  end
end
