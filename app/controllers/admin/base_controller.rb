module Admin
  class BaseController < ApplicationController
    skip_before_filter :require_login
  end
end