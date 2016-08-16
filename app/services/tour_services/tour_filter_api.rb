module TourServices
  class TourFilterApi
    def initialize(user:,
                   status:,
                   type:,
                   vehicle_type:,
                   show_only_my_tours: false,
                   latitude:,
                   longitude:,
                   distance:,
                   time_range: 24,
                   page:,
                   per:,
                   before: nil,
                   author: nil,
                   invitee: nil)
      @user = user
      @status = status.is_a?(Array) ? status : [status]
      @type = type
      @vehicle_type = vehicle_type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @show_only_my_tours = show_only_my_tours
      @time_range = (time_range || 24).to_i
      @page = page
      @per = per
      @before = before
      @author = author
      @invitee = invitee
    end

    def tours
      tours = Tour.includes(:tour_points, :join_requests, :entourage_invitations, :user, user: :organization)
      tours = tours.where(status: status.map {|s| Tour.statuses[s]}) if status.try(:compact).present?
      tours = tours.where(tour_type: formated_types) if type
      tours = tours.where(vehicle_type: Tour.vehicle_types[vehicle_type.to_sym]) if vehicle_type
      tours = filter_box(tours) if latitude && longitude

      if show_only_my_tours
        tours = tours.where(join_requests:
                                          {
                                              user: @user,
                                              status: JoinRequest::ACCEPTED_STATUS
                                          })
      end

      if invitee
        tours = tours.where(entourage_invitations:
                                          {
                                              invitee: invitee,
                                              status: EntourageInvitation::ACCEPTED_STATUS
                                          })
      end

      tours = tours.where(user: author) if author
      tours = tours.where("tours.created_at > ?", time_range.hours.ago)
      tours = tours.order("tours.updated_at DESC")
      if page || per
        tours.page(page).per(per)
      elsif before
        tours.before(DateTime.parse(before))
      else
        tours
      end
    end

    private
    attr_reader :user, :status, :type, :vehicle_type, :show_only_my_tours, :latitude, :longitude, :distance, :time_range, :page, :per, :before, :author, :invitee

    def filter_box(tours)
      points = TourPoint.within_bounding_box(box).select(:tour_id).distinct
      tours.where(id: points)
    end

    def box
      Geocoder::Calculations.bounding_box([latitude, longitude],
                                          (distance || 10),
                                          units: :km)
    end

    def formated_types
      type.gsub(" ", "").split(",")
    end
  end
end