module EntourageServices
  class OutingBuilder
    attr_reader :callback, :user, :params

    def initialize(params:, user:)
      @callback = Callback.new
      @params = params
      @user = user
    end

    def create
      yield callback if block_given?

      outing = Outing.new(params)
      outing.user = user
      outing.status = :open
      outing.group_type = :outing
      outing.entourage_type = :contribution
      outing.category = :social
      outing.uuid = SecureRandom.uuid

      return callback.on_success.try(:call, outing.reload) if outing.save

      callback.on_failure.try(:call, outing)
    end

    class << self
      def batch_update_dates outing:, params:
        metadata = params[:metadata].to_h.reverse_merge(outing.metadata)

        outing.update_attributes!({ metadata: metadata }.merge(force_relatives_dates: true))
      end
    end
  end
end
