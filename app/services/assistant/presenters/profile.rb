module Assistant
  module Presenters
    # What the user declared about themselves: city and distance they accept, what they look for,
    # interests, availability, gender when given. Nothing is deduced: no situation, no segment.
    class Profile
      GOALS = %w[offer_help ask_for_help ask_and_offer_help].freeze
      GENDERS = %w[female male].freeze # `secret` is the answer "not given"

      def initialize user
        @user = user
      end

      def as_json(*)
        {
          city: user.address&.city.presence,
          travelDistanceKm: user.travel_distance,
          goal: goal,
          interests: user.interest_list.to_a,
          availability: user.availability.presence || {},
          gender: gender
        }
      end

      private

      attr_reader :user

      def goal
        declared = user.goal_choice.presence || user.goal
        declared if GOALS.include?(declared.to_s)
      end

      def gender
        user.gender.to_s.presence_in(GENDERS)
      end
    end
  end
end
