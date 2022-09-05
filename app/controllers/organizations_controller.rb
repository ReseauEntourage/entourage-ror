class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_manager!, only: [:edit, :update]
  before_action :set_organization, except: [:new, :create]
  before_action :authenticate_admin!, only: [:new, :create]

  def dashboard
    tours = Tour.joins(:user).where(users: { organization_id: @organization.id })
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
      on.success do |organization, user|
        @organization = organization
        render :edit, success: "L'organisation a bien été créé"
      end

      on.failure do |organization, user|
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
    @tours = TourServices::TourFilterWeb.new(params: params, organization: @organization, user: @current_user).filter
    if params[:only_points]=="true"
      points = @tours.map {|tour| tour.tour_points.ordered}.flatten
      render json: {points: points}
    else
      tours_json = V1::GoogleMap::TourSerializer.new(tours: @tours).to_json
      render json: tours_json, status: 200
    end
  end

  def simplified_tours
    @tours = TourServices::SimplifiedTourFilter.new(params: params, organization: @organization, user: @current_user).filter
    if params[:only_points]=="true"
      points = @tours.map {|tour| tour.simplified_tour_points.ordered }.flatten
      render json: {points: points}
    else
      tours_json = V1::GoogleMap::SimplifiedTourSerializer.new(tours: @tours).to_json
      render json: tours_json, status: 200
    end
  end

  def encounters
    @tours = TourServices::SimplifiedTourFilter.new(params: params, organization: @organization, user: @current_user).filter
    @encounters = Encounter.includes(tour: :user).where(tour: @tours).order(:id)
    if @box
      @encounters = @encounters.within_bounding_box(@box)
    end
    @tour_count = @tours.count
    @tourer_count = @tours.select(:user_id).distinct.count
    @encounter_count = @encounters.count

    user_default.date_range = params[:date_range] if params[:date_range]
    user_default.tour_types = params[:tour_type].split(",") if params[:tour_type].present?

    encounters = JSON.parse(ActiveModel::Serializer::CollectionSerializer.new(@encounters, serializer: V1::EncounterSerializer).to_json)
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
    redirect_to dashboard_organizations_path, notice: 'message programmé'
  end

  private

  def is_number? string
    true if Float(string) rescue false
  end

  def organization_params
    params.require(:organization).permit(:name, :description, :phone, :address, :logo_url, :test_organization, tour_report_cc: [], user: [:first_name, :last_name, :phone, :email])
  end

  def set_organization
    @organization = @current_user.organization
  end

  def user_default
    @user_default ||= PreferenceServices::UserDefault.new(user: @current_user)
  end

end
