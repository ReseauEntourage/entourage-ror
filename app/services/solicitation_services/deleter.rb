module SolicitationServices
  class Deleter
    attr_reader :user, :solicitation, :callback

    def initialize user:, solicitation:
      @user = user
      @solicitation = solicitation

      @callback = DeleterCallback.new
    end

    def delete params
      yield callback if block_given?

      return callback.on_not_authorized.try(:call) unless user.id == solicitation.user_id

      solicitation.assign_attributes(params.merge({ status: :closed }))

      if solicitation.save
        callback.on_success.try(:call, solicitation)
      else
        callback.on_failure.try(:call, solicitation)
      end
    end
  end

  class DeleterCallback < Callback
    attr_accessor :on_not_authorized

    def not_authorized(&block)
      @on_not_authorized = block
    end
  end
end
