module ContributionServices
  class Deleter
    attr_reader :user, :contribution, :callback

    def initialize user:, contribution:
      @user = user
      @contribution = contribution

      @callback = DeleterCallback.new
    end

    def delete
      yield callback if block_given?

      return callback.on_not_authorized.try(:call) unless user.id == contribution.user_id

      if contribution.update(status: :closed)
        callback.on_success.try(:call, contribution)
      else
        callback.on_failure.try(:call, contribution)
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