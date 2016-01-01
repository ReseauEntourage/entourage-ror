module TourServices
  class TourFilter
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
      filter_date
      filter_type

      self.tours
    end

    private
    attr_reader :params, :organization, :user

    def box
      return @box if @box
      if (params[:sw].present? && params[:ne].present? && ![params[:sw], params[:ne]].include?("NaN-NaN"))
        ne = params[:ne].split('-').map(&:to_f)
        sw = params[:sw].split('-').map(&:to_f)
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
        tours_with_point_in_box = TourPoint.unscoped.within_bounding_box(box).select(:tour_id).distinct
        self.tours = self.tours.where(id: tours_with_point_in_box)
      end
    end

    def filter_org
      if !params[:org].nil?
        self.tours = self.tours.where(users: { organization_id: params[:org] })
      end
    end

    def filter_date
      if params[:date_range].nil?
        self.tours = self.tours.where("tours.updated_at >= ?", Time.now.monday)
      else
        user_default.date_range = params[:date_range]
        date_range = params[:date_range].split('-').map { |s| Date.strptime(s, '%d/%m/%Y') }
        self.tours = self.tours.where("tours.updated_at between ? and ?", date_range[0].beginning_of_day, date_range[1].end_of_day)
      end
    end

    def filter_type
      if params[:tour_type].present?
        tour_types = params[:tour_type].split(",")
        user_default.tour_types = tour_types
        self.tours = self.tours.where(tour_type: tour_types)
      end
    end

    def user_default
      @user_default ||= PreferenceServices::UserDefault.new(user: user)
    end
  end
end