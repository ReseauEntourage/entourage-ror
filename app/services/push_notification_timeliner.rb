class PushNotificationTimeliner
  attr_reader :user, :method, :moderator_id

  def initialize user_id, verb
    @user = User.find(user_id)
    @method = "user_on_#{verb.to_s}".to_sym
  end

  def run
    return if @user.is_ask_for_help? # we do not send welcome notifications to this profile
    return unless respond_to?(@method)

    send(@method)
  rescue => e
    Rails.logger.error "PushNotificationTrigger: #{e.message}"
  end

  # link_to resources
  def user_on_h1_after_registration
    notify(
      instance: nil,
      params: {
        object: "Bienvenue sur le réseau social vraiment social",
        extra: {
          welcome: true,
          stage: :h1,
          instance: :resources
        }
      }
    )
  end

  # link_to default neighborhood
  def user_on_j2_after_registration
    notify(
      instance: @user.default_neighborhood,
      params: {
        object: "C'est le moment de se lancer",
        extra: {
          welcome: true,
          stage: :j2
        }
      }
    )
  end

  def user_on_j5_after_registration
    return user_on_j5_after_registration_outings if user_has_outings?
    return user_on_j5_after_registration_actions if user_has_actions?

    user_on_j5_after_registration_create_action
  end

  # link_to outings
  def user_on_j5_after_registration_outings
    notify(
      instance: nil,
      params: {
        object: "#{nb_people} personnes se sont faits de nouveaux amis lors d'un événement Entourage",
        extra: {
          welcome: true,
          stage: :j8,
          instance: :outings
        }
      }
    )
  end

  # link_to actions
  def user_on_j5_after_registration_actions
    notify(
      instance: nil,
      params: {
        object: "Donnez un coup de pouce à vos voisins",
        extra: {
          welcome: true,
          stage: :j8,
          instance: :actions
        }
      }
    )
  end

  # link_to create_action
  def user_on_j5_after_registration_create_action
    notify(
      instance: nil,
      params: {
        object: "Pas d'entraide autour de vous ? Créez-là !",
        extra: {
          welcome: true,
          stage: :j8,
          instance: :create_action
        }
      }
    )
  end

  # link_to external link
  def user_on_j8_after_registration
    notify(
      instance: nil,
      params: {
        object: "A vous de jouer",
        extra: {
          welcome: true,
          stage: :j8
        }
      }
    )
  end

  # no link
  def user_on_j11_after_registration
    notify(
      instance: nil,
      params: {
        object: "Déjà 10 jours",
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
end
