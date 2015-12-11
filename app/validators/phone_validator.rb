class PhoneValidator
  def self.valid?(phone)
    phone && phone.gsub(" ","").match(/\A(\+[3]{2}|0)([1-9][-.\s]?(\d{2}[-.\s]?){3}\d{2})/).present?
  end
end