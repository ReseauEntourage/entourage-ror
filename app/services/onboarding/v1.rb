module Onboarding
  module V1
    ENTOURAGES = {
      'Clichy Levallois'=>2851,
      'Marseille'=>2852,
      'Toulouse'=>2853,
      'Nice'=>2854,
      'Nantes'=>2855,
      'Strasbourg'=>2856,
      'Montpellier'=>2857,
      'Bordeaux'=>2858,
      'Lille'=>2859,
      'Rennes'=>2860,
      'Reims'=>2861,
      'Le Havre'=>2862,
      'Saint-Étienne'=>2863,
      'Toulon'=>2864,
      'Grenoble'=>2865,
      'Dijon'=>2866,
      'Angers'=>2867,
      'Nîmes'=>2868,
      'Aix-en-Provence'=>2869,
      'Saint-Denis 93'=>2870,
      'Versailles'=>2871,
      'Boulogne-Billancourt'=>2872,
      'Nanterre'=>2873,
      'Courbevoie'=>2874,
      'Antony'=>2875,
      'Lyon Ouest'=>2876,
      'Lyon Est'=>2877,
      'Paris République'=>2878,
      'Paris 17 et 9'=>2879,
      'Paris 15'=>2880,
      'Paris 5'=>2881
    }

    def self.pinned_entourage_for area, user:
      return if user.pro?
      entourage_id = ENTOURAGES[area]
      return if entourage_id.nil?
      return if user.join_requests.exists?
      entourage_id
    end

    def self.announcement_for area, user:
      return if user.pro?
      entourage_id = ENTOURAGES[area]
      return if entourage_id.nil?
      Announcement.new(
        id: 5,
        title: "#{user.first_name}, on n'attend plus que vous !",
        body: "Conseils, rencontres, idées d'action... Rentrez en contact avec les personnes du quartier.",
        action: "C'est parti !",
        url: "#{ENV['DEEPLINK_SCHEME']}://entourage/#{entourage_id}",
        author: User.find_by(email: "guillaume@entourage.social"),
        position: 1
      )
    end

    def self.chat_message_for user
      ChatMessage.new(
        user_id: User.find_by(email: 'guillaume@entourage.social').id,
        content: "Bienvenue dans la conversation de groupe, #{user.first_name} !\n\nParlez un peu de vous aux autres membres : quel est votre quartier, avez vous des idées d'actions, avez-vous besoin d'aide...",
        created_at: Time.now
      )
    end

    def self.join_request_success join_request
      AcceptJoinRequestJob
        .set(wait_until: join_request.created_at + 15.seconds)
        .perform_later(join_request)
    end

    def self.entourage_metadata entourage
      area = ENTOURAGES.invert[entourage.id]
      is_onboarding = area.present?

      mp_params = { "is Onboarding Entourage" => is_onboarding }
      mp_params["Onboarding Entourage Area"] = area if is_onboarding
      [is_onboarding, mp_params]
    end

    def self.is_onboarding? entourage
      ENTOURAGES.has_value? entourage.id
    end

    class AcceptJoinRequestJob < ActiveJob::Base
      def perform join_request
        JoinRequestsServices::JoinRequestUpdater.new(
          join_request: join_request,
          status: 'accepted',
          message: nil,
          current_user: join_request.joinable.user
        ).update
      end
    end
  end
end
