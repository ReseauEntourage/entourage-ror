module CnilAnonymize
  FIELDS = %w{email phone address created_at}

  def self.anonymize phone
    return unless user = user_by_phone(phone)

    user.update_attributes!(
      email: "anonymized@#{Time.now.to_i}",
      phone: "+33100000000-#{Time.now.to_i}",
      first_name: "This user has been anonymized",
      last_name: nil,
      avatar_key: nil,
      deleted: true,
      manager: false,
      admin: false,
      address_id: nil
    )

    Address.where(user_id: user.id).delete_all
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