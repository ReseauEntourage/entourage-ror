module AnnouncementServices
  class Finder
    DEFAULT_DISTANCE=10

    def initialize user:, latitude:, longitude:
      @user = user
      @latitude = latitude
      @longitude = longitude
    end

    def announcements
      begin
        @latitude  = Float(@latitude)
        @longitude = Float(@longitude)
      rescue => e
        raise Api::V1::ApiError, "Invalid latitude/longitude."
      end

      announcements = FeedServices::AnnouncementsService.new(
        feeds: [],
        user: @user,
        offset: 0,
        area: FeedServices::FeedRequestArea.new(@latitude, @longitude),
        last_page: true,
      ).announcements

      FeedServices::FeedWithCursor.new(
        announcements,
        cursor: nil,
        next_page_token: nil,
        metadata: {}
      )
    end
  end
end
