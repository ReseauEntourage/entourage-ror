# @tours = Tour.includes(:tour_points).includes(:tours_users).includes(:user).where(nil)
# @tours = @tours.type(params[:type]) if params[:type].present?
# @tours = @tours.vehicle_type(Tour.vehicle_types[params[:vehicle_type]]) if params[:vehicle_type].present?
# @tours = @tours.where(status: Tour.statuses[params[:status]]) if params[:status].present?
#
# if (params[:latitude].present? && params[:longitude].present?)
#   center_point = [params[:latitude], params[:longitude]]
#   distance = params.fetch(:distance, 10)
#   box = Geocoder::Calculations.bounding_box(center_point, distance, :units => :km)
#   points = TourPoint.within_bounding_box(box).select(:tour_id).distinct
#   @tours = @tours.where(id: points)
# end
#
# @tours = @tours.where("updated_at > ?", 24.hours.ago).order(updated_at: :desc).limit(params.fetch(:limit, 10))
# @presenters = TourCollectionPresenter.new(tours: @tours)
# render json: @tours, status: 200, each_serializer: ::V1::TourSerializer, scope: current_user

#{?token}{&status}{&type}&latitude}{&longitude}{&distance}{&page}{&per}

module EntourageServices
  class EntourageFinder
    def initialize(user:, status:, type:, latitude:, longitude:, distance:, page:, per:)
      @user = user
      @status = status
      @type = type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @page = page
      @per = per
    end

    def entourages
      entourages = Entourage.includes(:entourages_users, :user)
      entourages = entourages.where(status: status) if status
      entourages = entourages.where(entourage_type: type) if type
      entourages = entourages.within_bounding_box(box) if latitude && longitude
      entourages = entourages.where("updated_at > ?", 1.month.ago)
      entourages.order(updated_at: :desc).page(page).per(per)
    end

    private
    attr_reader :user, :status, :type, :latitude, :longitude, :distance, :page, :per

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          (distance || 100),
                                          units: :km)
    end
  end
end