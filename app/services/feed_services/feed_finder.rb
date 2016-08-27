module FeedServices
  class FeedFinder
    def initialize(user:,
                   status:,
                   type:,
                   latitude:,
                   longitude:,
                   distance:,
                   show_my_entourages_only: false,
                   time_range: 24,
                   page:,
                   per:,
                   before: nil,
                   author: nil,
                   invitee: nil)
      @user = user
      @status = status
      @type = type
      @latitude = latitude
      @longitude = longitude
      @distance = distance
      @show_my_entourages_only = show_my_entourages_only
      @time_range = (time_range || 24).to_i
      @page = page
      @per = per
      @before = before
      @author = author
      @invitee = invitee
    end

    def feeds
      feeds = ToursEntourage.includes(:user)
      feeds = feeds.where(status: status) if status
      feeds = feeds.where(status: entourage_type: formated_types) if type
      feeds = feeds.within_bounding_box(box) if latitude && longitude
      feeds = feeds.where("feeds.created_at > ?", time_range.hours.ago)
      feeds = feeds.where(user: author) if author

      if show_my_entourages_only
        #Refactor query to get join requests directly from view
        feeds = feeds.where(join_requests:
                              {
                                  user: @user,
                                  status: JoinRequest::ACCEPTED_STATUS
                              })
      end

      if invitee
        feeds = feeds.where(entourage_invitations:
                                          {
                                              invitee: invitee,
                                              status: EntourageInvitation::ACCEPTED_STATUS
                                          })
      end
      feeds = feeds.order("feeds.updated_at DESC")
    end

    private
    attr_reader :user, :status, :type, :latitude, :longitude, :distance, :show_my_entourages_only, :time_range, :page, :per, :before, :author, :invitee

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