module Admin
  class SmalltalksController < Admin::BaseController
    before_action :set_smalltalk, only: [:show, :show_members, :show_messages]

    def index
      @smalltalks = Smalltalk.includes(:members).order(updated_at: :desc).page(page).per(per)
    end

    def show
    end

    def show_members
      @members = @smalltalk.members.page(page).per(per)
    end

    def show_messages
      @messages = @smalltalk.chat_messages.order(created_at: :desc).page(page).per(per).includes(:user, :survey, :translation)
    end

    private

    def set_smalltalk
      @smalltalk = Smalltalk.find(params[:id])
    end

    def page
      params[:page] || 1
    end

    def per
      params[:per] || 25
    end
  end
end
