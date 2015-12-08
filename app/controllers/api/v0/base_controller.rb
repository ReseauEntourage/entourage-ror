module Api
  module V0
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session

    end
  end
end
