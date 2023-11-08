# send push notif to user having registered recently
module Onboarding
  class Timeliner
    attr_reader :user, :method, :moderator_id

    TITLE_H1 = "Bienvenue chez Entourage 👌"
    OFFER_H1 = "Le saviez-vous ? Il suffit d'une vidéo pour déconstruire vos préjugés !"
    ASK_H1 = "Vous n'imaginez pas tout ce que contient votre nouvelle app : venez la découvrir !"

    TITLE_J2 = "Passez dire bonjour 👋"
    OFFER_J2 = "Votre groupe de voisins ne demande qu'à vous connaître !"
    ASK_TITLE_J2_OUTING = "Vous avez 4 minutes ?"
    ASK_J2 = "Regardez une courte vidéo pour tout comprendre à votre nouvelle application"

    TITLE_J5_OUTING = "Coucou, c'est encore nous ! 🕺"
    OFFER_J5_OUTING = "Le virtuel, c'est sympa deux minutes, venez faire une rencontre dans la vraie vie !"

    TITLE_J5_ACTION = "Coucou, c'est encore nous ! 🕺"
    OFFER_J5_ACTION = "Vous avez deux minutes pour donner un coup de pouce à vos voisins ?"

    TITLE_J5_CREATE_ACTION = "Coucou, c'est encore nous ! 🕺"
    OFFER_J5_CREATE_ACTION = "Prenez deux minutes pour proposer votre aide autour de vous"

    ASK_TITLE_J5 = "Passez dire bonjour 👏"
    ASK_J5 = "Votre groupe de voisins ne demande qu'à vous connaître"

    TITLE_J8 = "A vous de jouer ! 📱"
    OFFER_J8 = "Un petit quiz anti-préjugés : on parie que vous allez apprendre des choses ?"

    ASK_TITLE_J8_OUTING = "Coucou, c'est encore nous ! 🕺"
    ASK_J8_OUTING = "Le virtuel, c'est sympa deux minutes, venez faire une rencontre dans la vraie vie !"

    ASK_TITLE_J8_ACTION = "Coucou, c'est encore nous ! 🕺"
    ASK_J8_ACTION = "Jetez un oeil aux coups de pouce publiés près de chez vous."

    ASK_TITLE_J8_CREATE_ACTION = "Coucou, c'est encore nous ! 🕺"
    ASK_J8_CREATE_ACTION = "Une pétanque, un café ou juste une balade : proposez une sortie à vos voisins !"

    TITLE_J11 = "Entourage c'est la famille !"
    OFFER_J11 = "On peut le dire, vous faites maintenant partie de la communauté Entourage. Ça se fête ! 🎉"
    ASK_J11 = "On peut le dire, vous faites maintenant partie de la communauté Entourage. Ça se fête ! 🎉"

    def initialize user_id, verb
      @user = User.find(user_id)
      @method = "#{user_profile}_on_#{verb.to_s}".to_sym
    end

    def run
      return if @user.deleted?
      return unless respond_to?(@method)

      return if user_profile == :ask_for_help

      send(@method)
    rescue => e
      Rails.logger.error "PushNotificationTrigger: #{e.message}"
    end

    # h1
    def offer_help_on_h1_after_registration
      notify(
        instance: :resources,
        params: {
          object: TITLE_H1,
          content: OFFER_H1,
          extra: { stage: :h1 }
        }
      )
    end

    def ask_for_help_on_h1_after_registration
      notify(
        instance: :resources,
        params: {
          object: TITLE_H1,
          content: ASK_H1,
          extra: { stage: :h1 }
        }
      )
    end

    # j2
    def offer_help_on_j2_after_registration
      notify(
        instance: @user.default_neighborhood,
        params: {
          object: TITLE_J2,
          content: OFFER_J2,
          extra: { stage: :j2 }
        }
      )
    end

    def ask_for_help_on_j2_after_registration
      notify(
        instance: @user.default_neighborhood,
        params: {
          object: ASK_TITLE_J2_OUTING,
          content: ASK_J2,
          extra: { stage: :j2 }
        }
      )
    end

    # j5
    def offer_help_on_j5_after_registration
      return offer_help_on_j5_after_registration_outings if user_has_outings?
      return offer_help_on_j5_after_registration_actions if user_has_actions?

      offer_help_on_j5_after_registration_create_action
    end

    def ask_for_help_on_j5_after_registration
      notify(
        instance: @user.default_neighborhood,
        params: {
          object: ASK_TITLE_J5,
          content: ASK_J5,
          extra: { stage: :j5 }
        }
      )
    end

    def offer_help_on_j5_after_registration_outings
      notify(
        instance: :outings,
        params: {
          object: TITLE_J5_OUTING,
          content: OFFER_J5_OUTING,
          extra: { stage: :j5 }
        }
      )
    end

    def offer_help_on_j5_after_registration_actions
      notify(
        instance: :solicitations,
        params: {
          object: TITLE_J5_ACTION,
          content: OFFER_J5_ACTION,
          extra: { stage: :j5 }
        }
      )
    end

    def offer_help_on_j5_after_registration_create_action
      notify(
        instance: :contribution,
        params: {
          object: TITLE_J5_CREATE_ACTION,
          content: OFFER_J5_CREATE_ACTION,
          extra: { stage: :j5 }
        }
      )
    end

    # j8
    def offer_help_on_j8_after_registration
      notify(
        instance: nil,
        params: {
          object: TITLE_J8,
          content: OFFER_J8,
          extra: { stage: :j8 }
        }
      )
    end

    def ask_for_help_on_j8_after_registration
      return ask_for_help_on_j8_after_registration_outings if user_has_outings?
      return ask_for_help_on_j8_after_registration_actions if user_has_actions?

      ask_for_help_on_j8_after_registration_create_action
    end

    def ask_for_help_on_j8_after_registration_outings
      notify(
        instance: :outings,
        params: {
          object: ASK_TITLE_J8_OUTING,
          content: ASK_J8_OUTING,
          extra: { stage: :j8 }
        }
      )
    end

    def ask_for_help_on_j8_after_registration_actions
      notify(
        instance: :solicitations,
        params: {
          object: ASK_TITLE_J8_ACTION,
          content: ASK_J8_ACTION,
          extra: { stage: :j8 }
        }
      )
    end

    def ask_for_help_on_j8_after_registration_create_action
      notify(
        instance: :solicitation,
        params: {
          object: ASK_TITLE_J8_CREATE_ACTION,
          content: ASK_J8_CREATE_ACTION,
          extra: { stage: :j8 }
        }
      )
    end

    # j11
    def offer_help_on_j11_after_registration
      notify(
        instance: nil,
        params: {
          object: TITLE_J11,
          content: OFFER_J11,
          extra: { stage: :j11 }
        }
      )
    end

    def ask_for_help_on_j11_after_registration
      notify(
        instance: nil,
        params: {
          object: TITLE_J11,
          content: ASK_J11,
          extra: { stage: :j11 }
        }
      )
    end

    def notify instance:, params: {}
      notify_push(instance: instance, params: params)
      notify_inapp(instance: instance, params: params)
    end

    def notify_push instance:, params: {}
      instance = PushNotificationLinker.get(instance)

      PushNotificationService.new.send_notification(
        nil,
        params[:object],
        params[:content],
        [@user],
        instance[:instance],
        instance[:instance_id],
        instance.merge(params[:extra] || {})
      )
    end

    def notify_inapp instance:, params: {}
      instance = PushNotificationLinker.get(instance)

      InappNotificationServices::Builder.new(@user).instanciate(
        context: params[:extra][:stage],
        sender_id: nil,
        instance: instance[:instance],
        instance_id: instance[:instance_id],
        post_id: nil,
        referent: instance[:instance],
        referent_id: instance[:instance_id],
        title: params[:object],
        content: params[:content]
      )
    end

    private

    def user_has_outings?
      OutingsServices::Finder.new(@user, Hash.new).find_all.where(online: false).any?
    end

    def user_has_actions?
      user_has_solicitations? # is_ask_for_help profiles are excluded from welcome notifications
    end

    def user_has_solicitations?
      SolicitationServices::Finder.new(@user, Hash.new).find_all.any?
    end

    def user_profile
      if @user.is_ask_for_help?
        :ask_for_help
      else
        :offer_help
      end
    end
  end
end
