module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_admin!

    def community
      @community ||= begin
        $server_community
      end
    end
  end
end
