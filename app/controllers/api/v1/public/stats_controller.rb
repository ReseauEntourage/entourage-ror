module Api
  module V1
    module Public
      class StatsController < Api::V1::Public::BaseController
        def index
          json_stats = $redis.get("entourage::stats")
          if json_stats.blank?
            json_stats = ::V1::Public::StatsSerializer.new.to_json
            $redis.setex("entourage::stats", 1.hour, json_stats)
          end
          render json: json_stats, status: 200
        end
      end
    end
  end
end
