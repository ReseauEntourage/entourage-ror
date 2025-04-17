module Admin
  class SmalltalksController < Admin::BaseController
    before_action :authenticate_admin!

    def index
      @smalltalks = Smalltalk.includes(:members).order(updated_at: :desc)
    end
  end
end
