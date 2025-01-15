class Conversation < Entourage
  default_scope { where(group_type: :conversation, public: false) }

  scope :search_by_id, -> (string) {
    return unless string.present?
    return unless string.match?(/\A\d+\z/)

    where(id: string)
  }
end
