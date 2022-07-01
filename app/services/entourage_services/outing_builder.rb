module EntourageServices
  class OutingBuilder
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

      success = false

      ApplicationRecord.transaction do
        success = outing.save && new_join_request(outing).save

        unless success
          raise ActiveRecord::Rollback
        end
      end

      return callback.on_success.try(:call, outing.reload) if success

      callback.on_failure.try(:call, outing)
    end

    private
    attr_reader :callback, :user, :params

    def new_join_request outing
      JoinRequest.create(joinable: outing, user: user, role: :organizer, status: :accepted)
    end
  end
end
