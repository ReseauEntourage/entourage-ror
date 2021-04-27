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
    url = UserServices::Avatar.new(user: user).thumbnail_url
    return unless url

    image_tag(url, height: '128', width: '128')
  end

  def validation_status_action_link
    return if user.anonymized?

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
    self.format_name_part first_name
  end

  def self.format_name_part name_part
    name_part = name_part&.squish.presence
    return nil if name_part.nil?

    if name_part.match?(/^[[:alpha:]]/)
      name_part[0] = name_part[0].upcase
    end

    name_part
  end

  def display_name
    self.class.display_name user
  end

  def self.display_name user
    first_name = UserPresenter.format_first_name(user.first_name)
    last_name_first = user.last_name&.strip&.first.presence
    if last_name_first&.match?(/^[[:alpha:]]/)
      last_name_first = last_name_first.capitalize + '.'
    end
    [first_name, last_name_first].compact.join(' ').presence
  end

  def self.full_name user
    [user.first_name, user.last_name].map { |name_part|
      format_name_part(name_part)
    }.compact.join(' ').presence
  end

  def full_name
    self.class.full_name(user)
  end

  def self.has_partner_role_title? user
    format_name_part(user.partner_role_title) != nil
  end

  def self.partner_role_title user
    format_name_part(user.partner_role_title) || "Membre"
  end

  private
  attr_reader :user
end
