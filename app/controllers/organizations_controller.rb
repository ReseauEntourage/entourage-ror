class OrganizationsController < GuiController
  attr_writer :push_notification_service
  
  before_filter :location_filter, only: [:encounters, :tours]
  before_filter :set_organization

  def dashboard
    my_tours = Tour.joins(:user).where(users: { organization_id: @organization.id })
    week_tours = my_tours.where("tours.updated_at >= ?", DateTime.now.monday)
    @tour_count = week_tours.count
    @tourer_count = week_tours.select(:user_id).distinct.count
    @total_length = week_tours.sum(:length)
    @encounter_count = Encounter.where(tour: week_tours).count

    #TODO : improve query (take, group_by)
    @latest_tours = (my_tours.order('tours.updated_at DESC').take 8).group_by { |t| t.updated_at.to_date }
  end

  def statistics
  end

  def edit
  end
  
  def update
    if (@organization.update_attributes(organization_params))
      redirect_to edit_organization_path(@organization), notice: 'Organization was successfully updated.'
    else
      redirect_to edit_organization_path(@organization), notice: 'Error'
    end
  end
  
  def tours
    orgs = [@organization.id] + @current_user.coordinated_organizations.map(&:id)
    @tours = Tour.includes(:snap_to_road_tour_points)
                 .joins(:user)
                 .where(users: { organization_id: orgs })
    
    if @box
      tours_with_point_in_box = SnapToRoadTourPoint.unscoped.within_bounding_box(@box).select(:tour_id).distinct
      @tours = @tours.where(id: tours_with_point_in_box)
    end
    if !params[:org].nil?
      @tours = @tours.where(users: { organization_id: params[:org] })
    end
    if params[:date_range].nil?
      @tours = @tours.where("tours.updated_at >= ?", Time.now.monday)
    else
      date_range = params[:date_range].split('-').map { |s| Date.strptime(s, '%d/%m/%Y') }
      @tours = @tours.where("tours.updated_at between ? and ?", date_range[0].beginning_of_day, date_range[1].end_of_day)
    end
    @tours = @tours.where(tour_type: params[:tour_type].split(",")) if params[:tour_type].present?
    @presenters = TourCollectionPresenter.new(tours: @tours)
    @tours
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
  end
  
  def map_center
    render json: [@current_user.default_latitude ||= 48.858859, @current_user.default_longitude ||= 2.3470599]
  end
  
  def send_message
    sender = @current_user.full_name
    push_notification_service.send_notification sender, params[:object], params[:message], @organization.users
    render plain: 'message envoyé', status: 200
  end
  
  private
  
  def location_filter
    if (params[:sw].present? && params[:ne].present?)
      ne = params[:ne].split('-').map(&:to_f)
      sw = params[:sw].split('-').map(&:to_f)
      @current_user.default_latitude = (ne[0] + sw[0]) / 2
      @current_user.default_longitude = (ne[1] + sw[1]) / 2
      @current_user.save
      @box = sw + ne
    end
  end
  
  def organization_params
    params.require(:organization).permit(:name, :description, :phone, :address, :logo_url)
  end
  
  def push_notification_service
    @push_notification_service ||= PushNotificationService.new
  end

  def set_organization
    @organization = current_user.organization
  end

end
