module CnilAnonymize
  def self.anonymize phone
    return unless user = user_by_phone(phone)

    user.anonymize!
  rescue ActiveRecord::RecordNotFound => e
    puts "Could not find user. Please provide a valid phone number: #{e.message}"
  rescue ActiveRecord::RecordInvalid => e
    puts "Could not anonymize user: #{e.message}"
  end

  private

  def self.user_by_phone(phone)
    User.find_by!(phone: Phone::PhoneBuilder.new(phone: phone).format)
  end
end