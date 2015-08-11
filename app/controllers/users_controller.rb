class UsersController < ApplicationController

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  skip_before_filter :require_login
  before_filter :admin_authentication, except: :login
  attr_writer :android_notification_service, :sms_notification_service

  def index
    @users = User.all
    render status: 200
  end

  def create
    @user = User.new(user_params)
    if @user.save
      render "show", status: 201
    else
      @entity = @user
      render 'application/400', status: 400
    end
  end

  def update
    if params[:id] && User.find_by(id: params[:id])
      @user = User.find(params[:id])
      @user.update_attributes(user_params)
      render "show", status: 200
    else
      render '404', status: 404
    end
  end

  def destroy
    if params[:id] && User.find_by(id: params[:id])
      user = User.find(params[:id])
      user.destroy
      head 204
    else
      render '404', status: 404
    end
  end

  def login
    @user = User.includes(:organization).find_by_phone_and_sms_code params[:phone], params[:sms_code]
    if @user.nil?
      render 'error', status: :bad_request
    else
      @user.device_id = params['device_id'] if params['device_id'].present?
      @user.device_type = params['device_type'] if params['device_type'].present?
      @user.save
      
      @tour_count = @user.tours.count
      @encounter_count = @user.encounters.count
    end
  end
  
  def send_message
    device_ids = User.where(id: params['user_ids']).where.not(device_id: nil).pluck(:device_id)
    android_notification_service.send_notification(params['sender'], params['object'], params['content'], device_ids)
    head 200
  end
  
  def send_sms
    user = User.find_by(id: params[:id])
    if user.nil?
      render '404', status: 404
    else
      sms_notification_service.send_notification(user.phone, user.sms_code)
      head 200
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :phone, :organization_id)
  end
  
  def android_notification_service
    @android_notification_service ||= AndroidNotificationService.new(Rpush)
  end
  
  def sms_notification_service
    @sms_notification_service ||= SmsNotificationService.new
  end

end
