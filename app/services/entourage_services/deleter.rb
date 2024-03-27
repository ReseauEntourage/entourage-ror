module EntourageServices
  class Deleter
    attr_reader :user, :entourage, :callback

    def initialize user:, entourage:
      @user = user
      @entourage = entourage

      @callback = DeleterCallback.new
    end

    def delete params = {}
      yield callback if block_given?

      return callback.on_not_authorized.try(:call) unless user.id == entourage.user_id

      entourage.assign_attributes(params.merge({ status: :closed }))

      if entourage.save
        callback.on_success.try(:call, entourage)
      else
        callback.on_failure.try(:call, entourage)
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
