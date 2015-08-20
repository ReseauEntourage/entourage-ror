class OrganizationController < GuiController

  def dashboard
    tours = Tour.where("updated_at >= ?", Time.now.monday)
    @tour_count = tours.count
    @tourer_count = tours.select(:user_id).distinct.count
    @encounter_count = Encounter.where(tour: tours).count
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
    @tours = Tour.all.joins(:user)
      .where(users: { organization_id: @organization.id })
      .where("tours.updated_at >= ?", Time.now.monday)
  end
  
  private
  
  def organization_params
    params.require(:organization).permit(:name, :description, :phone, :address)
  end
end
