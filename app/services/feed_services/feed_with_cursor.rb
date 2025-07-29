module FeedServices
  class FeedWithCursor
    def initialize entries, cursor:, next_page_token:, metadata: {}
      @cursor = cursor
      @next_page_token = next_page_token
      @entries = entries
      @metadata = metadata
    end

    attr_reader :entries, :cursor, :next_page_token, :metadata
  end
end
