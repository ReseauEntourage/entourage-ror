class ModerationArea < ApplicationRecord
  validates :slack_moderator_id, length: { in: 9..11 }, allow_nil: true

  belongs_to :moderator, class_name: :User, optional: true
  belongs_to :animator, class_name: :User, optional: true
  belongs_to :mobilisator, class_name: :User, optional: true
  belongs_to :sourcing, class_name: :User, optional: true
  belongs_to :accompanyist, class_name: :User, optional: true
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

  def slack_moderator
    moderator
  end

  def slack_moderator_with_fallback
    return slack_moderator if slack_moderator.try(:slack_id)
    return mobilisator if mobilisator.try(:slack_id)
    return accompanyist if accompanyist.try(:slack_id)
    return sourcing if sourcing.try(:slack_id)
    return default_interlocutor if default_interlocutor.try(:slack_id)

    nil
  end

  def slack_moderator_id
    slack_moderator.try(:slack_id)
  end

  def slack_moderator_id_with_fallback
    return slack_moderator_with_fallback.slack_id if slack_moderator_with_fallback

    SlackServices::Notifier::DEFAULT_SLACK_MODERATOR_ID
  end

  def default_interlocutor
    ModerationServices.moderator_if_exists(community: :entourage)
  end

  def interlocutor_for_user user
    return default_interlocutor unless user.present?
    return accompanyist_with_fallback if user.is_ask_for_help? && activity?
    return sourcing_with_fallback if user.is_ask_for_help?
    return sourcing_with_fallback if user.association?

    mobilisator_with_fallback
  end

  def animator_with_fallback
    animator || mobilisator || community_builder || default_interlocutor
  end

  def mobilisator_with_fallback
    mobilisator || accompanyist || community_builder || default_interlocutor
  end

  def sourcing_with_fallback
    sourcing || accompanyist || mobilisator || community_builder || default_interlocutor
  end

  def accompanyist_with_fallback
    accompanyist || sourcing || mobilisator || community_builder || default_interlocutor
  end

  def community_builder_with_fallback
    community_builder || mobilisator || accompanyist || default_interlocutor
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
    when /\A\d\d\z/
      "dep_#{departement}".to_sym
    else
      raise "Unhandled departement #{departement.inspect}"
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
