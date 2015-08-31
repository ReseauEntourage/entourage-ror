class OrganizationController < GuiController
  attr_writer :push_notification_service

  def dashboard
    my_tours = Tour.joins(:user).where(users: { organization_id: @organization.id })
    week_tours = my_tours.where("tours.updated_at >= ?", DateTime.now.monday)
    @tour_count = week_tours.count
    @tourer_count = week_tours.select(:user_id).distinct.count
    @total_length = week_tours.sum(:length)
    @encounter_count = Encounter.where(tour: week_tours).count
    @latest_tours = (my_tours.order('tours.updated_at DESC').take 8).group_by { |t| t.updated_at.to_date }
  end

  def edit
  end
  
  def update
    if (@organization.update_attributes(organization_params))
      redirect_to :organization_edit, notice: 'Organization was successfully updated.'
    else
      redirect_to :organization_edit, notice: 'Error'
    end
  end
  
  def tours
    @tours = Tour.joins(:user).includes(:tour_points)
      .where(users: { organization_id: @organization.id })
    if params[:date_range].nil?
      @tours = @tours.where("tours.updated_at >= ?", Time.now.monday)
    else
      date_range = params[:date_range].split('-').map { |s| Date.strptime(s, '%d/%m/%Y') }
      @tours = @tours.where("tours.updated_at between ? and ?", date_range[0].beginning_of_day, date_range[1].end_of_day)
    end
    @tours = @tours.where(tour_type: params[:tour_type]) if params[:tour_type].present?
  end
  
  def encounters
    tours
    @encounters = Encounter.where(tour: @tours)
  end
  
  def send_message
    sender = @current_user.full_name
    push_notification_service.send_notification sender, params[:object], params[:message], @organization.users
    render plain: 'message envoyé', status: 200
  end
  
  private
  
  def organization_params
    params.require(:organization).permit(:name, :description, :phone, :address)
  end
  
  def push_notification_service
    @push_notification_service ||= PushNotificationService.new
  end

end
