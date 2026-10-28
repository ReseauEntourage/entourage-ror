module UserServices
  class CreatedContent
    STATUS_LABELS = {
      'active' => 'Actif',
      'updated' => 'Modifié',
      'deleted' => 'Supprimé',
      'offensible' => 'Détecté comme offensant',
      'offensive' => 'Modéré comme offensant',
      'scheduled' => 'Programmé',
    }

    attr_accessor :user, :messageable_type

    def initialize user, messageable_type:
      @user = user
      @messageable_type = messageable_type
    end

    def get
      messages = ChatMessage
        .where(user_id: user.id, messageable_type: messageable_type)
        .order(created_at: :desc)

      groups = messageable_type.constantize.unscoped
        .where(id: messages.map(&:messageable_id))
        .index_by(&:id)

      messages.map do |message|
        group = groups[message.messageable_id]
        next nil unless group

        {
          message: message,
          group: group,
          kind: message.has_parent? ? :comment : :post,
          extrait: message.content(true).to_s.truncate(80),
          status_label: STATUS_LABELS[message.status] || message.status.to_s,
        }
      end.compact
    end
  end
end
