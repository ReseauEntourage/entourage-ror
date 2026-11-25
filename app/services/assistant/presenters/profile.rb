module Assistant
  module Presenters
    # What the user declared about themselves: city, distance they accept, what they look for,
    # interests, availability, gender when given. Nothing is deduced: no situation, no segment.
    # Values are the ones of the contract with the assistant (design.md, EN-9878).
    class Profile
      GOALS = { 'offer_help' => 'give-help', 'ask_for_help' => 'seek-help', 'ask_and_offer_help' => 'both' }.freeze
      # `secret` is the answer "not given" in the app, `other` does not exist there: both give null.
      GENDERS = { 'female' => 'woman', 'male' => 'man' }.freeze
      DAYS = { '1' => 'monday', '2' => 'tuesday', '3' => 'wednesday', '4' => 'thursday', '5' => 'friday', '6' => 'saturday', '7' => 'sunday' }.freeze

      def initialize user
        @user = user
      end

      def as_json(*)
        {
          city: user.address&.city.presence,
          distanceKm: user.travel_distance,
          goal: GOALS[(user.goal_choice.presence || user.goal).to_s],
          # the order of the list of the app: the database gives no order
          interests: ::Tag.interest_list & user.interest_list.to_a,
          availabilities: availabilities,
          gender: GENDERS[user.gender.to_s]
        }
      end

      private

      attr_reader :user

      # The app stores { "1" => ["09:00-12:00"] } (1 = Monday): "monday 09:00-12:00".
      def availabilities
        user.availability.to_h.sort_by { |day, _| day.to_s }.flat_map do |day, slots|
          name = DAYS[day.to_s]
          name ? Array(slots).map { |slot| "#{name} #{slot}" } : []
        end
      end
    end
  end
end
