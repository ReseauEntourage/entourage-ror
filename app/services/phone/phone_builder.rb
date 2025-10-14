module Phone
  class PhoneBuilder
    def initialize(phone:)
      @phone = phone
    end

    def format
      return if @phone.nil?
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
  end
end
