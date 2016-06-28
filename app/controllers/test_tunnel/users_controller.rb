module TestTunnel
  class UsersController < TestTunnel::BaseController
    before_action :authenticate_admin!

    def step1
    end

    def step2
      @user = User.where(phone: Phone::PhoneBuilder.new(phone: params[:phone]).format).first
    end

    def step3
      @user = User.find(params[:id])
      @upload_presenter = UploadPresenter.new
    end

    def step4
      @user = User.find(params[:id])
    end

    private

    def authenticate_admin!
      unless ENV["STAGING"]
        return render text: "Unauthorised", status: 401 unless User.where(id: session[:user_id]).first.try(:admin)
      end
    end
  end
end