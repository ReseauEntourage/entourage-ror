module NeighborhoodServices
  class Deleter
    attr_reader :user, :neighborhood, :callback

    def initialize user:, neighborhood:
      @user = user
      @neighborhood = neighborhood

      @callback = DeleterCallback.new
    end

    def delete
      yield callback if block_given?

      return callback.on_not_authorized.try(:call) unless user.id == neighborhood.user_id

      if neighborhood.update(status: :deleted)
        callback.on_success.try(:call, neighborhood)
      else
        callback.on_failure.try(:call, neighborhood)
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
