# send push notif to user having registered recently
module Onboarding
  class Timeliner
    attr_reader :user, :method, :moderator_id

    TITLE_H1 = "Bienvenue chez Entourage"
    OFFER_H1 = "Le saviez-vous ? Il suffit d'une vidéo pour déconstruire vos préjugés !"
    ASK_H1 = "(ask_for) Bienvenue sur le réseau social vraiment social"

    TITLE_J2 = "Et si on parlait de vous ?"
    OFFER_J2 = "Les présentations, c'est dans les deux sens ! Passez dire bonjour à votre groupe de voisins"
    ASK_J2 = "(ask_for) C'est le moment de se lancer"

    TITLE_J5_OUTING = "Coucou, c'est encore nous !"
    OFFER_J5_OUTING = "Le virtuel, c'est sympa deux minutes, prenez-en deux de plus pour faire une vraie rencontre !"
    ASK_J5_OUTING = "(ask_for) %s personnes se sont faits de nouveaux amis lors d'un événement Entourage"

    TITLE_J5_ACTION = "Coucou, c'est encore nous !"
    OFFER_J5_ACTION = "Le virtuel, c'est sympa deux minutes, prenez-en deux de plus pour faire une vraie rencontre !"
    ASK_J5_ACTION = "(ask_for) Donnez un coup de pouce à vos voisins"

    TITLE_J5_CREATE_ACTION = "Coucou, c'est encore nous !"
    OFFER_J5_CREATE_ACTION = "Prenez deux minutes pour proposer votre aide autour de vous"
    ASK_J5_CREATE_ACTION = "(ask_for) Pas d'entraide autour de vous ? Créez-là !"

    TITLE_J8 = "A vous de jouer"
    OFFER_J8 = "Un petit quiz anti-préjugés : on parie que vous allez apprendre des choses ?"
    ASK_J8 = "(ask_for) A vous de jouer"

    TITLE_J11 = "Entourage c'est la famille !"
    OFFER_J11 = "On peut le dire, vous faites maintenant partie de la communauté Entourage. Ça se fête !"
    ASK_J11 = "(ask_for) Déjà 10 jours"

    def initialize user_id, verb
      @user = User.find(user_id)
      @method = "#{user_profile}_on_#{verb.to_s}".to_sym
    end

    def run
      return if @user.deleted?
      return unless respond_to?(@method)

      send(@method)
    rescue => e
      Rails.logger.error "PushNotificationTrigger: #{e.message}"
    end

    # h1
    def offer_help_on_h1_after_registration
      notify(
        instance: nil,
        params: {
          object: TITLE_H1,
          content: OFFER_H1,
          extra: {
            welcome: true,
            stage: :h1,
            url: :resources
          }
        }
      )
    end

    def ask_for_help_on_h1_after_registration
      notify(
        instance: nil,
        params: {
          object: ASK_H1,
          extra: {
            welcome: true,
            stage: :h1,
            url: :resources
          }
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
          extra: {
            welcome: true,
            stage: :j2,
            url: :home
          }
        }
      )
    end

    def ask_for_help_on_j2_after_registration
      notify(
        instance: @user.default_neighborhood,
        params: {
          object: ASK_J2,
          extra: {
            welcome: true,
            stage: :j2,
            url: :home
          }
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
      return ask_for_help_on_j5_after_registration_outings if user_has_outings?
      return ask_for_help_on_j5_after_registration_actions if user_has_actions?

      ask_for_help_on_j5_after_registration_create_action
    end

    def offer_help_on_j5_after_registration_outings
      notify(
        instance: nil,
        params: {
          object: TITLE_J5_OUTING,
          content: OFFER_J5_OUTING,
          extra: {
            welcome: true,
            stage: :j8,
            url: :outings
          }
        }
      )
    end

    def ask_for_help_on_j5_after_registration_outings
      notify(
        instance: nil,
        params: {
          object: ASK_J5_OUTING % "n/a",
          extra: {
            welcome: true,
            stage: :j8,
            url: :outings
          }
        }
      )
    end

    def offer_help_on_j5_after_registration_actions
      notify(
        instance: nil,
        params: {
          object: TITLE_J5_ACTION,
          content: OFFER_J5_ACTION,
          extra: {
            welcome: true,
            stage: :j8,
            url: :solicitations
          }
        }
      )
    end

    def ask_for_help_on_j5_after_registration_actions
      notify(
        instance: nil,
        params: {
          object: ASK_J5_ACTION,
          extra: {
            welcome: true,
            stage: :j8,
            url: :solicitations
          }
        }
      )
    end

    def offer_help_on_j5_after_registration_create_action
      notify(
        instance: nil,
        params: {
          object: TITLE_J5_CREATE_ACTION,
          content: OFFER_J5_CREATE_ACTION,
          extra: {
            welcome: true,
            stage: :j8,
            url: :create_action
          }
        }
      )
    end

    def ask_for_help_on_j5_after_registration_create_action
      notify(
        instance: nil,
        params: {
          object: ASK_J5_CREATE_ACTION,
          extra: {
            welcome: true,
            stage: :j8,
            url: :create_action
          }
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
          extra: {
            welcome: true,
            stage: :j8
          }
        }
      )
    end

    def ask_for_help_on_j8_after_registration
      notify(
        instance: nil,
        params: {
          object: ASK_J8,
          extra: {
            welcome: true,
            stage: :j8
          }
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
          extra: {
            welcome: true,
            stage: :j11
          }
        }
      )
    end

    def ask_for_help_on_j11_after_registration
      notify(
        instance: nil,
        params: {
          object: ASK_J11,
          extra: {
            welcome: true,
            stage: :j11
          }
        }
      )
    end

    def notify instance:, params: {}
      notify_push(instance: instance, params: params)
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

    private

    def user_has_outings?
      OutingsServices::Finder.new(@user, Hash.new).find_all.any?
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
