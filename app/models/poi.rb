class Poi < ApplicationRecord
  include Geolocalizable
  include Recommandable

  enum source: { entourage: 0, soliguide: 1 }, _prefix: :source

  validates_presence_of :name, :category
  validates :latitude, :longitude, numericality: true
  validates :partner_id, presence: true, allow_nil: true
  belongs_to :category, optional: true
  has_and_belongs_to_many :categories, optional: true

  geocoded_by :adress

  scope :validated, -> { where(validated: true) }
  scope :not_source_entourage, -> { where.not(source: Poi.sources[:entourage]) }
  scope :not_source_soliguide, -> { where.not(source: Poi.sources[:soliguide]) }

  scope :with_category_ids, -> (category_ids) {
    return unless category_ids.present?
    return unless category_ids.any?

    joins(:categories_pois).where(categories_pois: { category_id: category_ids })
  }

  scope :with_partners_filters, -> (partners_filters) {
    return unless partners_filters.present?
    return unless partners_filters.any?

    @pois = @pois.joins("left join partners on partners.id = partner_id")
    clauses = ["partner_id is null"]
    clauses << "donations_needs is not null"  if partners_filters.include?(:donations)
    clauses << "volunteers_needs is not null" if partners_filters.include?(:volunteers)
    @pois = @pois.where(clauses.join(" OR "))
  }

  scope :in_departement, -> (departement) do
    if departement.to_sym == :hors_zone
      departements = ModerationArea.only_departements.join('|')

      where("adress !~ ?", "(,|\s)#{departements}\\d{3}")
    else
      where("adress ~ ?", "(,|\s)#{departement}\\d{3}")
    end
  end

  (1..7).each do |iterator|
    define_method("category_#{iterator}") do
      categories[iterator - 1]
    end
  end

  class << self
    def find_by_uuid uuid
      if uuid.start_with?('s')
        find_by(source_id: uuid[1..])
      else
        find(uuid)
      end
    end

    alias_method :find_by_id_or_uuid, :find_by_uuid
  end

  def uuid
    return "s#{source_id}" if source_soliguide?
    return unless id

    id.to_s
  end

  def source_url
    return unless source_soliguide?

    "https://soliguide.fr/fiche/#{source_id}"
  end

  def address
    adress
  end

  def address= address
    self[:adress] = address
  end

  def category_ids= category_ids
    if category_id.nil?
      self[:category_id] = category_ids.reject(&:blank?).first
    end

    super category_ids
  end

  #
  # Textsearch

  def self.enable_textsearch?
    !Rails.env.test?
  end

  def self.textsearch_expression(*fields)
    text = fields.map { |field| "coalesce(#{field}, '')" }.join(" || ' ' || ")

    # We 'strip' the tsvector to make it more compact.
    # This will interfere with position and weight operators, but we don't use them for now.
    #
    # We also 'unaccent' the text before parsing.
    # This will degrade the quality of the matches. A better solution might be to have both the
    # accented and unaccented words with a lesser coeff for the latter?
    "strip(to_tsvector('french', unaccent(#{text})))"
  end

  UPDATE_SQL = "update pois set textsearch = #{textsearch_expression(:name, :description, :audience)}".freeze

  def update_textsearch!
    return unless self.class.enable_textsearch?
    return if destroyed?
    self.class.connection.execute("#{UPDATE_SQL} where id = #{id}").clear
  end

  def self.update_textsearch!
    connection.execute(UPDATE_SQL).clear
  end

  after_commit :update_textsearch!

  scope :text_search, -> (query) {
    return unless query.present?

    where("textsearch @@ plainto_tsquery('french', unaccent(?))", query)
  }
end
