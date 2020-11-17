class Poi < ActiveRecord::Base

  validates_presence_of :name, :category
  validates :latitude, :longitude, numericality: true
  validates :partner_id, presence: true, allow_nil: true
  belongs_to :category
  has_and_belongs_to_many :categories

  geocoded_by :adress

  scope :validated, -> { where(validated: true) }

  scope :around, -> (latitude, longitude, distance) do
    distance ||= 10
    box = Geocoder::Calculations.bounding_box([latitude, longitude], distance, units: :km)
    within_bounding_box(box)
  end

  def uuid
    id.to_s unless id.nil?
  end

  def source
    :entourage
  end

  def source_url
    nil
  end

  def address
    adress
  end

  def hours
    nil
  end

  def languages
    nil
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

  scope :text_search, -> (query) { where("textsearch @@ plainto_tsquery('french', unaccent(?))", query) }
end
