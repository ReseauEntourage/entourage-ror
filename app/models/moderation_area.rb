class ModerationArea < ApplicationRecord
  belongs_to :animator, class_name: :User, optional: true
  belongs_to :sourcing, class_name: :User, optional: true
  belongs_to :community_builder, class_name: :User, optional: true

  scope :no_hz, -> { where.not(departement: "*") }
  scope :in_region, -> (region) {
    return unless region.present?

    where(departement: ModerationServices::Region.departments_in(region))
  }

  HORS_ZONE = "*"

  def region
    ModerationServices::Region.for_department(departement)
  end

  def slack_moderator_with_fallback object
    user = object if object.is_a?(User)
    user = object.user if object.respond_to?(:user)

    return unless user.present?
    return animator_with_fallback if user.is_offer_help?
    return animator_with_fallback if user.ambassador?

    sourcing_with_fallback
  end

  def slack_moderator_id_with_fallback object
    return ModerationServices::DEFAULT_SLACK_MODERATOR_ID unless moderator = slack_moderator_with_fallback(object)
    return ModerationServices::DEFAULT_SLACK_MODERATOR_ID unless moderator.slack_id.present?

    moderator.slack_id
  end

  def default_interlocutor
    ModerationServices.moderator_if_exists(community: :entourage)
  end

  def interlocutor_for_user user
    return default_interlocutor unless user.present?
    return sourcing_with_fallback if user.is_ask_for_help?
    return sourcing_with_fallback if user.association?

    animator_with_fallback
  end

  def animator_with_fallback
    animator || default_interlocutor
  end

  def sourcing_with_fallback
    sourcing || default_interlocutor
  end

  def community_builder_with_fallback
    community_builder || default_interlocutor
  end

  def departement_slug
    self.class.departement_slug(departement)
  end

  def name_with_departement
    case departement
    when '*', '_'
      name
    else
      "#{name} (#{departement})"
    end
  end

  def short_name
    case departement
    when '*'
      'HZ'
    when '_'
      'SZ'
    else
      departement
    end
  end

  def self.departement_slug departement
    case departement
    when '*'
      :hors_zone
    when '_'
      :sans_zone
    when 'FR'
      :national
    else
      "dep_#{departement}".to_sym
    end
  end

  def self.departement slug
    return '*' if slug.to_sym == :hors_zone
    return '_' if slug.to_sym == :sans_zone
    raise ArgumentError.new("Unhandled slug #{slug.inspect}") unless slug.start_with? 'dep_'

    slug[4..-1]
  end

  def self.national
    new(name: "National", departement: "FR")
  end

  def self.no_zone
    new(name: "Sans zone", departement: "_")
  end

  def self.all_with_national_with_no_zone
    [national] + all.order(:id) + [no_zone]
  end

  def self.all_with_no_zone
    all.order(:id) + [no_zone]
  end

  def self.all_without_no_zone
    all.order(:id)
  end

  def self.all_slugs
    (pluck(:departement) + [no_zone.departement]).map { |d| ModerationArea.departement_slug(d) }
  end

  def self.slugs
    (pluck(:departement) - ['*']).map { |d| ModerationArea.departement_slug(d) }
  end

  def self.by_slug
    Hash[all_with_no_zone.map { |a| [a.departement_slug, a] }]
  end

  def self.by_slug_with_national
    Hash[all_with_national_with_no_zone.map { |a| [a.departement_slug, a] }]
  end

  def self.by_slug_without_no_zone
    Hash[all_without_no_zone.map { |a| [a.departement_slug, a] }]
  end

  def self.only_departements
    pluck(:departement) - ['*', '_']
  end
end
