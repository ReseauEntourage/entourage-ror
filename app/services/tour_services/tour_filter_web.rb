module TourServices
  class TourFilterWeb
    attr_accessor :tours

    def initialize(params:, organization:, user:)
      @params = params
      @organization = organization
      @user = user
      set_tours
    end

    def filter
      filter_box
      filter_org
      filter_date
      filter_type

      @tours
    end

    #private
    attr_reader :params, :organization, :user

    def box
      return @box if @box
      if (params[:sw].present? && params[:ne].present? && ![params[:sw], params[:ne]].include?("NaN-NaN"))
        ne = params[:ne].split('_').map(&:to_f)
        sw = params[:sw].split('_').map(&:to_f)
        return if [ne, sw].any? {|coord| coord.blank? } ||
                  [ne, sw].any? {|coord| coord.count != 2 }

        user_default.latitude = (ne[0] + sw[0]) / 2
        user_default.longitude = (ne[1] + sw[1]) / 2
        @box = sw + ne
        @box
      end
    end

    def set_tours
      @tours = Tour.includes(:tour_points)
                   .joins(:user)
                   .where(users: { organization_id: orgs })
    end

    def orgs
      [organization.id] + user.coordinated_organizations.map(&:id)
    end

    def filter_box
      if box
        tours_with_point_in_box = TourPoint.within_bounding_box(box).select(:tour_id).distinct
        @tours = @tours.where(id: tours_with_point_in_box)
      end
    end

    def filter_org
      if !params[:org].nil?
        @tours = @tours.where(users: { organization_id: params[:org] })
      end
    end

    def filter_date
      if params[:date_range].nil?
        @tours = @tours.where("tours.updated_at >= ?", Time.now.monday)
      else
        user_default.date_range = params[:date_range]
        date_range = params[:date_range].split('-').map { |s| Date.strptime(s, '%d/%m/%Y') }
        @tours = @tours.where("tours.updated_at between ? and ?", date_range[0].beginning_of_day, date_range[1].end_of_day)
      end
    end

    def filter_type
      if params[:tour_type].present?
        tour_types = params[:tour_type].split(",")
        user_default.tour_types = tour_types
        @tours = @tours.where(tour_type: tour_types)
      end
    end

    def user_default
      @user_default ||= PreferenceServices::UserDefault.new(user: user)
    end
  end
end