module MatchingServices
  class Client
    def self.session
      OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    end
  end
end
