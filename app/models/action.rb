class Action < Entourage
  include Sectionable

  default_scope { where(group_type: :action, entourage_type: [:ask_for_help, :contribution]).order(created_at: :desc) }

  scope :filtered_with_user_profile, -> (user) {
    return where(entourage_type: :contribution) if user.is_ask_for_help?

    where(entourage_type: :ask_for_help)
  }
end
