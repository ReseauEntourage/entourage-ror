class OrganizationsController < ApplicationController
  attr_writer :push_notification_service

  before_filter :authenticate_user!
  before_filter :authenticate_manager!, only: [:edit, :update]
  before_filter :location_filter, only: [:encounters, :tours]
  before_filter :set_organization

  def dashboard
    tours = Tour.joins(:user).where(users: { organization_id: @organization.id })
    @tours_presenter = TourCollectionPresenter.new(tours: tours)
    @user_presenter = UserPresenter.new(user: @current_user)
  end

  def statistics
    @user_presenter = UserPresenter.new(user: @current_user)
  end

  def edit
  end
  
  def update
    flash[:notice]= "L'association a bien été mise à jour" if @organization.update(organization_params)
    render :edit
  end
  
  def tours
    orgs = [@organization.id] + @current_user.coordinated_organizations.map(&:id)
    @tours = Tour.includes(:tour_points)
                 .joins(:user)
                 .where(users: { organization_id: orgs })
    
    if @box
      tours_with_point_in_box = TourPoint.unscoped.within_bounding_box(@box).select(:tour_id).distinct
      @tours = @tours.where(id: tours_with_point_in_box)
    end
    if !params[:org].nil?
      @tours = @tours.where(users: { organization_id: params[:org] })
    end
    if params[:date_range].nil?
      @tours = @tours.where("tours.updated_at >= ?", Time.now.monday)
    else
      user_default.date_range = params[:date_range]
      date_range = params[:date_range].split('-').map { |s| Date.strptime(s, '%d/%m/%Y') }
      @tours = @tours.where("tours.updated_at between ? and ?", date_range[0].beginning_of_day, date_range[1].end_of_day)
    end
    if params[:tour_type].present?
      tour_types = params[:tour_type].split(",")
      user_default.tour_types = tour_types
      @tours = @tours.where(tour_type: tour_types)
    end
    @presenters = TourCollectionPresenter.new(tours: @tours)
  end

  #TODO : DRY after refactoring tours display
  def simplified_tours
    orgs = [@organization.id] + @current_user.coordinated_organizations.map(&:id)
    @tours = Tour.includes(:simplified_tour_points)
                 .joins(:user)
                 .where(users: { organization_id: orgs })

    if @box
      tours_with_point_in_box = SimplifiedTour.unscoped.within_bounding_box(@box).select(:tour_id).distinct
      @tours = @tours.where(id: tours_with_point_in_box)
    end
    if !params[:org].nil?
      @tours = @tours.where(users: { organization_id: params[:org] })
    end
    if params[:date_range].nil?
      @tours = @tours.where("tours.updated_at >= ?", Time.now.monday)
    else
      user_default.date_range = params[:date_range]
      date_range = params[:date_range].split('-').map { |s| Date.strptime(s, '%d/%m/%Y') }
      @tours = @tours.where("tours.updated_at between ? and ?", date_range[0].beginning_of_day, date_range[1].end_of_day)
    end
    if params[:tour_type].present?
      tour_types = params[:tour_type].split(",")
      user_default.tour_types = tour_types
      @tours = @tours.where(tour_type: tour_types)
    end
    @presenters = TourCollectionPresenter.new(tours: @tours)
  end

  #TODO : DRY after refactoring tours display
  def snap_tours
    orgs = [@organization.id] + @current_user.coordinated_organizations.map(&:id)
    tours = Tour.includes(:snap_to_road_tour_points)
                 .joins(:user)
                 .where(users: { organization_id: orgs })

    if @box
      tours_with_point_in_box = SnapToRoadTourPoint.unscoped.within_bounding_box(@box).select(:tour_id).distinct
      tours = tours.where(id: tours_with_point_in_box)
    end
    if !params[:org].nil?
      tours = tours.where(users: { organization_id: params[:org] })
    end
    if params[:date_range].nil?
      tours = tours.where("tours.updated_at >= ?", Time.now.monday)
    else
      date_range = params[:date_range].split('-').map { |s| Date.strptime(s, '%d/%m/%Y') }
      tours = tours.where("tours.updated_at between ? and ?", date_range[0].beginning_of_day, date_range[1].end_of_day)
    end
    tours = tours.where(tour_type: params[:tour_type].split(",")) if params[:tour_type].present?
    @presenters = TourCollectionPresenter.new(tours: tours)
  end
  
  def encounters
    tours
    @encounters = Encounter.where(tour: @tours)
    if @box
      @encounters = @encounters.within_bounding_box(@box)
    end
    @tour_count = @tours.count
    @tourer_count = @tours.select(:user_id).distinct.count
    @encounter_count = @encounters.count

    user_default.date_range = params[:date_range] if params[:date_range]
    user_default.tour_types = params[:tour_type].split(",") if params[:tour_type].present?
  end
  
  def map_center
    render json: [user_default.latitude ||= 48.858859, user_default.longitude ||= 2.3470599]
  end
  
  def send_message
    send_message_service = TourServices::SendMessageService.new(params: params, current_user: @current_user)
    if send_message_service.should_send_now?
      push_notification_service.send_notification send_message_service.sender, send_message_service.object, send_message_service.content, send_message_service.recipients
      render plain: 'message envoyé', status: 200
    else
      render plain: 'message programmé', status: 200
    end
  end
  
  private
  
  def location_filter
    if (params[:sw].present? && params[:ne].present?)
      ne = params[:ne].split('-').map(&:to_f)
      sw = params[:sw].split('-').map(&:to_f)
      user_default.latitude = (ne[0] + sw[0]) / 2
      user_default.longitude = (ne[1] + sw[1]) / 2
      @box = sw + ne
    end
  end
  
  def organization_params
    params.require(:organization).permit(:name, :description, :phone, :address, :logo_url)
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
