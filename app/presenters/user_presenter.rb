class UserPresenter < ApplicationPresenter
  delegate :simplified_tour,
           :tour_types,
           :date_range, to: :user_default

  def initialize(user:)
    @user = user
  end

  def organization_members
    @user.organization.users.order("upper(first_name) ASC")
  end

  def can_send_push?
    user.device_id.present?
  end

  def user_default
    PreferenceServices::UserDefault.new(user: user)
  end

  def avatar
    image_tag(UserServices::Avatar.new(user: user).thumbnail_url, height: '128', width: '128')
  end

  def validation_status_action_link
    if user.validated?
      link_to("Bannir", Rails.application.routes.url_helpers.banish_admin_user_path(user), method: :put, class: "btn btn-danger", data: { confirm: "Vous allez supprimer l'avatar et bannir l'utilisateur, êtes vous sûr ?" })
    else
      link_to("Valider", Rails.application.routes.url_helpers.validate_admin_user_path(user), method: :put, class: "btn btn-success")
    end
  end

  def coordinated_organizations
    (user.coordinated_organizations + [user.organization]).compact.sort_by(&:name)
  end

  def self.format_first_name first_name
    first_name = first_name&.squish.presence
    return nil if first_name.nil?

    if first_name.match?(/^[[:alpha:]]/)
      first_name[0] = first_name[0].upcase
    end

    first_name
  end

  def display_name
    first_name = UserPresenter.format_first_name(user.first_name)
    last_name_first = user.last_name&.strip&.first.presence
    if last_name_first&.match?(/^[[:alpha:]]/)
      last_name_first = last_name_first.capitalize + '.'
    end
    [first_name, last_name_first].compact.join(' ').presence
  end

  private
  attr_reader :user
end
