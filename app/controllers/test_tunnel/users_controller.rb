module TestTunnel
  class UsersController < TestTunnel::BaseController
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
  end
end