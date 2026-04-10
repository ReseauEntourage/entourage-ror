class LegacyPhoneValidator
  def initialize(phone:)
    @phone = phone
  end

  def valid?
    return false unless phone

    french_number? ||
      belgian_number? ||
      maroc_number? ||
      dom_tom_number?
  end

  def foreign_number?
    formatted.start_with?('+') &&
      !formatted.start_with?('+33')
  end

  def french_number?
    formatted.match(/\A(\+33|0)[67]\d{8}\z/).present?
  end

  def belgian_number?
    formatted.match(/\A\+324\d{8}\z/).present?
  end

  def maroc_number?
    formatted.match(/\A\+212[67]\d{8}\z/).present?
  end

  DOM_TOM_RULES = [
    { country: '590', prefixes: %w[690 691] }, # Guadeloupe / St-Martin / St-Barth
    { country: '596', prefixes: %w[696 697] }, # Martinique
    { country: '594', prefixes: %w[694] },     # Guyane
    { country: '262', prefixes: %w[692 693 639] } # Réunion + Mayotte
  ].freeze

  def dom_tom_number?
    dom_tom_classic? || polynesia_number? || new_caledonia_number?
  end

  def dom_tom_classic?
    DOM_TOM_RULES.any? do |rule|
      match_dom_tom?(rule[:country], rule[:prefixes])
    end
  end

  def match_dom_tom?(country_code, prefixes)
    formatted.match(
      /\A\+#{country_code}(#{prefixes.join('|')})\d{6}\z/
    ).present?
  end

  def polynesia_number?
    # mobiles: 87, 88, 89 + 6 chiffres
    formatted.match(/\A\+689(87|88|89)\d{6}\z/).present?
  end

  def new_caledonia_number?
    # mobiles: 7xxxxx
    formatted.match(/\A\+6877\d{5}\z/).present?
  end

  def formatted
    phone
      .gsub(/[\s\-.]/, '')                  # supprime espaces, tirets, points
      .gsub(/(\A\+\d+)\(0+\)/, '\1')        # supprime (0) après indicatif
  end

  private

  attr_reader :phone
end
