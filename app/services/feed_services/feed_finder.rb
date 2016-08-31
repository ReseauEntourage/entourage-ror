module FeedServices
  class FeedFinder
    def initialize(user:,
                   page:,
                   per:,
                   before: nil)
      @user = user
      @page = page
      @per = per
      @before = before
    end

    def feeds
      feeds = user.feeds

      if page || per
        feeds.page(page).per(per)
      elsif before
        feeds.before(DateTime.parse(before)).limit(25)
      else
        feeds.limit(25)
      end
    end

    private
    attr_reader :user, :page, :per, :before
  end
end