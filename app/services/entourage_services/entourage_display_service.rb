module EntourageServices
  class EntourageDisplayService
    def initialize(entourage:, user:, params:)
      @entourage = entourage
      @user = user
      @params = params
    end

    def view
      return if user.anonymous?

      if params[:distance] && params[:feed_rank]
        EntourageDisplay.create(entourage: entourage,
                                user: user,
                                distance: params[:distance],
                                feed_rank: params[:feed_rank],
                                source: params[:source])
      end
    end

    private
    attr_reader :entourage, :user, :params
  end
end
