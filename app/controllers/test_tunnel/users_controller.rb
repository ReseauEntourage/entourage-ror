module TestTunnel
  class UsersController < TestTunnel::BaseController
    def step1
    end

    def step2
    end

    def step3
      @upload_presenter = Presenters::UploadPresenter.new
    end

    def step4
    end
  end
end