module Onboarding
  module V1
    ENTOURAGES = {
      'Clichy Levallois'=>3343,
      'Marseille'=>3344,
      'Toulouse'=>3345,
      'Nice'=>3346,
      'Nantes'=>3347,
      'Strasbourg'=>3348,
      'Montpellier'=>3349,
      'Bordeaux'=>3350,
      'Lille'=>3351,
      'Rennes'=>3352,
      'Reims'=>3353,
      'Le Havre'=>3354,
      'Saint-Étienne'=>3355,
      'Toulon'=>3356,
      'Grenoble'=>3357,
      'Dijon'=>3358,
      'Angers'=>3359,
      'Nîmes'=>3360,
      'Aix-en-Provence'=>3361,
      'Saint-Denis 93'=>3362,
      'Versailles'=>3363,
      'Boulogne-Billancourt'=>3364,
      'Nanterre'=>3365,
      'Courbevoie'=>3366,
      'Antony'=>3367,
      'Lyon Ouest'=>3368,
      'Lyon Est'=>3369,
      'Paris République'=>3370,
      'Paris 17 et 9'=>3371,
      'Paris 15'=>3372,
      'Paris 5'=>3373
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
      # LegacyAnnouncement.new(
      #   id: 5,
      #   title: "#{user.first_name}, on n'attend plus que vous !",
      #   body: "Conseils, rencontres, idées d'action... Rentrez en contact avec les personnes du quartier.",
      #   action: "C'est parti !",
      #   url: "#{ENV['DEEPLINK_SCHEME']}://entourage/#{entourage_id}",
      #   author: ModerationServices.moderator(community: user.community),
      #   position: 1
      # )
    end

    def self.chat_message_for user
      ChatMessage.new(
        user_id: ModerationServices.moderator(community: user.community).id,
        content: "Bienvenue dans la conversation de groupe, #{user.first_name} !\n\nParlez un peu de vous aux autres membres : quel est votre quartier, avez vous des idées d'actions, avez-vous besoin d'aide...",
        created_at: Time.now
      )
    end

    def self.entourage_metadata entourage
      area = ENTOURAGES.invert[entourage.id]
      is_onboarding = area.present?

      mp_params = { 'is Onboarding Entourage' => is_onboarding }
      mp_params['Onboarding Entourage Area'] = area if is_onboarding
      [is_onboarding, mp_params]
    end

    def self.is_onboarding? entourage
      ENTOURAGES.has_value? entourage.id
    end

    module Entourage
      extend ActiveSupport::Concern

      included do
        raise unless included_modules.include?(Experimental::AutoAccept::Joinable)
      end

      def auto_accept_join_requests?
        super || Onboarding::V1.is_onboarding?(self)
      end
    end
  end
end
