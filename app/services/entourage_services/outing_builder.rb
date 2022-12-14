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
      outing.public = true
      outing.uuid = SecureRandom.uuid

      return callback.on_success.try(:call, outing.reload) if outing.save

      callback.on_failure.try(:call, outing)
    end

    class << self
      def batch_update_dates outing:, params:
        metadata = params[:metadata].to_h.reverse_merge(outing.metadata)

        outing.update_attributes!({ metadata: metadata }.merge(force_relatives_dates: true))
      end

      def update_recurrency outing:, params:
        return true unless params.to_h.any?

        outing.assign_attributes(params)

        if outing.create_inbetween_occurrences?
          outing.create_inbetween_occurrences!
        elsif outing.cancel_odds_occurrences?
          outing.cancel_odds_occurrences!
        end

        outing.save
      end
    end
  end
end
