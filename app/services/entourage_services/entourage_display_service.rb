module EntourageServices
  class EntourageDisplayService
    def initialize(entourage:, user:, params:)
      @entourage = entourage
      @user = user
      @params = params
    end

    def view
      if params[:distance] && params[:feed_rank]
        EntourageDisplay.create(entourage: entourage,
                                distance: params[:distance],
                                feed_rank: params[:feed_rank],
                                source: params[:source])
      end
      EntourageServices::UsersAppetenceBuilder.new(user: user).view_entourage(entourage: entourage)
    end

    private
    attr_reader :entourage, :user, :params
  end
end