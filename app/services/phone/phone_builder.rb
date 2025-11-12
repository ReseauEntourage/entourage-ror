module Phone
  class PhoneBuilder
    PHONE_REGEX = /\A[+\d\s().-]{8,25}\z/

    def initialize(phone:)
      @phone = phone
    end

    def format
      return if @phone.nil?
      return @phone unless looks_like_phone_number?

      @phone = @phone.delete(' ')
                     .gsub(/(\A\+\d+)\(0+\)/, '\1')
                     .gsub(/[\s.()\-\u{202c}\u{202d}]/, '')
      add_international_code_for_french_numbers
      @phone
    end

    def add_international_code_for_french_numbers
      #ignore invalid phone numbers
      return unless LegacyPhoneValidator.new(phone: @phone).valid?

      #ignore foreign phone numbers
      return if LegacyPhoneValidator.new(phone: @phone).foreign_number?

      #ignore french number that do not start with regional code
      return unless @phone.match(/\A([0][1-9])/).present?

      @phone[0]='+33'
    end

    def looks_like_phone_number?
      return false if @phone.blank?
      return false if @phone.match?(/@/)

      digits = @phone.gsub(/\D/, '')
      @phone.strip.match?(/\A[+\d\s().-]{6,25}\z/) && digits.length.between?(8, 15)
    end
  end
end
