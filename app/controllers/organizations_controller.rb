class OrganizationsController < ApplicationController
  attr_writer :push_notification_service

  before_filter :authenticate_user!
  before_filter :authenticate_manager!, only: [:edit, :update]
  before_filter :set_organization, except: [:new, :create]
  before_filter :authenticate_admin!, only: [:new, :create]

  def dashboard
    tours = Tour.joins(user: :organization).where(users: { organization_id: @organization.id })
    @tours_presenter = TourCollectionPresenter.new(tours: tours)
    @user_presenter = UserPresenter.new(user: @current_user)
  end

  def statistics
    return redirect_to root_path
    @user_presenter = UserPresenter.new(user: @current_user)
  end

  def new
    @organization = Organization.new
  end

  def create
    builder = OrganizationServices::OrganizationBuiler.new(params: organization_params)
    builder.create do |on|
      on.create_success do |organization, user|
        @organization = organization
        render :edit, success: "L'organisation a bien été créé"
      end

      on.create_failure do |organization, user|
        @organization = organization
        render :new
      end
    end
  end

  def edit
  end
  
  def update
    flash[:notice]= "L'association a bien été mise à jour" if @organization.update(organization_params)
    render :edit
  end

  def tours
    @tours = TourServices::TourFilter.new(params: params, organization: @organization, user: @current_user).filter
    if params[:only_points]=="true"
      points = @tours.map {|tour| tour.tour_points }.flatten
      render json: {points: points}
    else
      tours_json = GoogleMap::TourSerializer.new(tours: @tours).to_json
      render json: tours_json, status: 200
    end
  end

  def simplified_tours
    @tours = TourServices::SimplifiedTourFilter.new(params: params, organization: @organization, user: @current_user).filter
    tours_json = GoogleMap::SimplifiedTourSerializer.new(tours: @tours).to_json
    render json: tours_json, status: 200
  end

  def snap_tours
    @tours = TourServices::SnapToRoadTourFilter.new(params: params, organization: @organization, user: @current_user).filter
    tours_json = GoogleMap::SnapToRoadTourSerializer.new(tours: @tours).to_json
    render json: {type: "FeatureCollection", features: tours_json}, status: 200
  end
  
  def encounters
    @tours = TourServices::TourFilter.new(params: params, organization: @organization, user: @current_user).filter
    @encounters = Encounter.includes(tour: :user).where(tour: @tours)
    if @box
      @encounters = @encounters.within_bounding_box(@box)
    end
    @tour_count = @tours.count
    @tourer_count = @tours.select(:user_id).distinct.count
    @encounter_count = @encounters.count

    user_default.date_range = params[:date_range] if params[:date_range]
    user_default.tour_types = params[:tour_type].split(",") if params[:tour_type].present?

    encounters = JSON.parse(ActiveModel::ArraySerializer.new(@encounters, each_serializer: EncounterSerializer).to_json)
    render json: {encounters: encounters,
                  stats: {encounter_count: @encounter_count,
                          tour_count: @tourer_count,
                          tourer_count: @tour_count }
                  }
  end
  
  def map_center
    render json: [user_default.latitude ||= 48.858859, user_default.longitude ||= 2.3470599], root: false
  end
  
  def send_message
    send_message_service = TourServices::SendMessageService.new(params: params, current_user: @current_user)
    if send_message_service.should_send_now?
      push_notification_service.send_notification send_message_service.sender, send_message_service.object, send_message_service.content, send_message_service.recipients
      redirect_to dashboard_organizations_path, notice: 'message envoyé'
    else
      redirect_to dashboard_organizations_path, notice: 'message programmé'
    end
  end
  
  private

  def is_number? string
    true if Float(string) rescue false
  end
  
  def organization_params
    params.require(:organization).permit(:name, :description, :phone, :address, :logo_url, user: [:first_name, :last_name, :phone, :email])
  end

  def set_organization
    @organization = @current_user.organization
  end
  
  def push_notification_service
    @push_notification_service ||= PushNotificationService.new
  end

  def user_default
    @user_default ||= PreferenceServices::UserDefault.new(user: @current_user)
  end

end
