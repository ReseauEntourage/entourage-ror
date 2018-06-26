module UserServices
  class AddressService
    def initialize(user:, params:)
      @user = user
      @params = params
      @callback = Callback.new
    end

    def update
      yield callback if block_given?

      address = user.address || user.build_address

      begin
        ActiveRecord::Base.transaction do
          address.update!(params)
          if address.id != user.address_id
            user.update_column(:address_id, address.id)
          end
        end
        success = true
      rescue ActiveRecord::ActiveRecordError
        success = false
      end


      if success
        callback.on_success.try(:call, user, address)
      else
        callback.on_failure.try(:call, user, address)
      end
      success
    end

    private
    attr_reader :user, :params, :callback
  end
end
