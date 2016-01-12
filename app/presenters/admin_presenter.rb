class AdminPresenter
  extend ActionView::Helpers::TagHelper
  extend ActionView::Helpers::TextHelper
  extend ActionView::Context
  extend ActionView::Helpers::UrlHelper

  def self.user_display_name(user)
    #"#{user.organization_name} - #{user.first_name} - #{user.last_name}"
    ""
  end

  def self.user_list
    users = User.includes(:organization).sort_by { |user| user_display_name(user) }
    content_tag(:ul, class: "dropdown-menu scrollable-menu") do
      users.map do |user|
        concat(content_tag(:li, link_to(user_display_name(user), Rails.application.routes.url_helpers.switch_user_admin_sessions_path(user_id: user.id))))
      end
    end
  end

end