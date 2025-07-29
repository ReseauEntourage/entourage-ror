module JoinRequestsServices
  class JoinRequestUpdater
    def initialize(join_request:, status:, message:, current_user:)
      @join_request = join_request
      @status = status
      @message = message
      @current_user = current_user
      @callback = UpdateJoinRequestCallback.new
    end

    def update
      yield callback if block_given?

      if status
        if status=='pending'
          pending
        else
          accept
        end
      elsif message
        update_message
      else
        callback.on_invalid_status.try(:call, status)
      end
    end

    def reject
      yield callback if block_given?
      unless current_user_authorised?
        return callback.on_not_authorised.try(:call) if join_request.user != current_user
      end

      if join_request.user == join_request.joinable.user
        return callback.on_remove_author.try(:call)
      end

      user_status = EntourageServices::JoinRequestStatus.new(join_request: @join_request)

      if join_request.user == current_user
        user_status.quit!
        return callback.on_quit.try(:call)
      end

      if user_status.reject!
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    private
    attr_reader :join_request, :callback, :status, :message, :current_user

    def accept
      unless status == 'accepted'
        return callback.on_invalid_status.try(:call, status)
      end

      if join_request.rejected?
        return callback.on_not_authorised.try(:call)
      end

      if !joinable.status.in?(['open', 'ongoing']) &&
         !(current_user.admin? || join_request.user.admin?)
        return callback.on_not_authorised.try(:call)
      end

      user_status = EntourageServices::JoinRequestStatus.new(join_request: join_request)
      if user_status.accept!
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    def quit
      unless status == 'cancelled'
        return callback.on_invalid_status.try(:call, status)
      end

      if join_request.user != current_user
        return callback.on_not_authorised.try(:call)
      end

      user_status = EntourageServices::JoinRequestStatus.new(join_request: join_request)
      if user_status.quit!
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    def pending
      unless status == 'pending'
        return callback.on_invalid_status.try(:call, status)
      end

      if join_request.user != current_user
        return callback.on_not_authorised.try(:call)
      end

      if !joinable.status.in?(['open', 'ongoing']) &&
         !join_request.user.admin?
        return callback.on_not_authorised.try(:call)
      end

      user_status = EntourageServices::JoinRequestStatus.new(join_request: join_request)
      if user_status.pending!
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    def update_message
      if join_request.user != current_user
        return callback.on_not_authorised.try(:call)
      end

      if join_request.update(message: message)
        callback.on_success.try(:call, join_request)
      else
        callback.on_failure.try(:call, join_request)
      end
    end

    def joinable
      join_request.joinable
    end

    def current_user_authorised?
      current_join_request = JoinRequest.where(joinable: joinable, user: current_user).first
      current_join_request && EntourageServices::JoinRequestStatus.new(join_request: current_join_request).accepted?
    end
  end

  class UpdateJoinRequestCallback < Callback
    attr_accessor :on_invalid_status, :on_not_authorised, :on_remove_author, :on_quit

    def invalid_status(&block)
      @on_invalid_status = block
    end

    def not_authorised(&block)
      @on_not_authorised = block
    end

    def remove_author(&block)
      @on_remove_author = block
    end

    def quit(&block)
      @on_quit = block
    end
  end
end
