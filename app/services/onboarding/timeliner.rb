# send push notif to user having registered recently
module Onboarding
  class Timeliner
    attr_reader :user, :method, :moderator_id

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
          object: "(offer) Bienvenue sur le réseau social vraiment social",
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
          object: "(ask_for) Bienvenue sur le réseau social vraiment social",
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
          object: "(offer) C'est le moment de se lancer",
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
          object: "(ask_for) C'est le moment de se lancer",
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
          object: "(offer) #{nb_people} personnes se sont faits de nouveaux amis lors d'un événement Entourage",
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
          object: "(ask_for) #{nb_people} personnes se sont faits de nouveaux amis lors d'un événement Entourage",
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
          object: "(offer) Donnez un coup de pouce à vos voisins",
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
          object: "(ask_for) Donnez un coup de pouce à vos voisins",
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
          object: "(offer) Pas d'entraide autour de vous ? Créez-là !",
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
          object: "(ask_for) Pas d'entraide autour de vous ? Créez-là !",
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
          object: "(offer) A vous de jouer",
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
          object: "(ask_for) A vous de jouer",
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
          object: "(offer) Déjà 10 jours",
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
          object: "(ask_for) Déjà 10 jours",
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
        nil,
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
