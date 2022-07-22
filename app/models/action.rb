class Action < Entourage
  include Sectionable

  default_scope { where(group_type: :action, entourage_type: [:ask_for_help, :contribution]).order(created_at: :desc) }
end
