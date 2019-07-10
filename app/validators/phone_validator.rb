class PhoneValidator
  def initialize(phone:)
    @phone = phone
  end

  def valid?
    return false unless phone
    return true if french_number?
    foreign_number?
  end

  def foreign_number?
    formatted.start_with?("+") &&
    !formatted.start_with?("+33")
  end

  def french_number?
    formatted.match(/\A(\+[3]{2}|0)([1-9][-.\s]?(\d{2}[-.\s]?){3}\d{2})/).present?
  end

  def formatted
    phone.gsub(" ", "")
         .gsub(/(\A\+\d+)\(0+\)/, '\1') # remove parenthesized zeroes after international prefix
  end

  private
  attr_reader :phone
end
