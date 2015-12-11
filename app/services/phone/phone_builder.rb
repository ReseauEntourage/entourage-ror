module Phone
  class PhoneBuilder
    def initialize(phone:)
      @phone = phone
    end

    def format
      return if @phone.nil?
      @phone = @phone.gsub(/[\s.-]/, "")
      @phone[0]="+33" if PhoneValidator.valid?(@phone) && @phone.match(/\A([0][1-9])/).present?
      @phone
    end
  end
end