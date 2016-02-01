module Phone
  class PhoneBuilder
    def initialize(phone:)
      @phone = phone
    end

    def format
      return if @phone.nil?
      @phone = @phone.gsub(/[\s.-]/, "")
      add_international_code_for_french_numbers
      @phone
    end

    def add_international_code_for_french_numbers
      #ignore invalid phone numbers
      return unless PhoneValidator.new(phone: @phone).valid?

      #ignore foreign phone numbers
      return if PhoneValidator.new(phone: @phone).foreign_number?

      #ignore french number that do not start with regional code
      return unless @phone.match(/\A([0][1-9])/).present?

      @phone[0]="+33"
    end
  end
end