class AdminPresenter < ApplicationPresenter
  extend ActionView::Helpers::TagHelper
  extend ActionView::Helpers::TextHelper
  extend ActionView::Helpers::UrlHelper
  extend ActionView::Context

  class << self
    include Rails.application.routes.url_helpers
  end

  def self.user_display_name(user)
    "#{user.organization_name} - #{user.first_name} - #{user.last_name}"
  end

  def self.user_list
    users = User.type_pro.sort_by { |user| user_display_name(user) }
    content_tag(:ul, class: 'dropdown-menu scrollable-menu') do
      users.map do |user|
        concat(content_tag(:li, link_to(user_display_name(user), switch_user_sessions_path(user_id: user.id))))
      end
    end
  end
end
