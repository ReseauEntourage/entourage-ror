class Conversation < Entourage
  default_scope { where(group_type: :conversation, public: false) }
end
