class ScheduledPushesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @scheduled_pushes = TourServices::SchedulePushService.all_scheduled_pushes(organization: current_user.organization)
  end

  def destroy
    date = Date.parse(params[:date])
    TourServices::SchedulePushService.new(organization: current_user.organization, date: date).destroy
    redirect_to scheduled_pushes_path
  end
end
