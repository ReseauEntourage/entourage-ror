class UserPresenter < ApplicationPresenter
  delegate :snap_to_road,
           :simplified_tour,
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

  private
  attr_reader :user
end