class PushNotificationTimeliner
  attr_reader :record, :method

  def initialize record, verb
    @record = record
    @method = "#{record.class.name.underscore}_on_#{verb.to_s}".to_sym
  end

  def run
    return unless respond_to?(@method)

    send(@method)
  rescue => e
    Rails.logger.error "PushNotificationTrigger: #{e.message}"
  end

  def user_on_h1_after_registration
    notify(
      sender_id: @record,
      users: [@record],
      params: {
        object: "Bienvenue sur le réseau social vraiment social",
        extra: {
          welcome: true,
          stage: :h1
        }
      }
    )
  end

  def user_on_j2_after_registration
    notify(
      sender_id: @record,
      users: [@record],
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
  end

  def user_on_j8_after_registration
    notify(
      sender_id: @record,
      users: [@record],
      params: {
        object: "A vous de jouer",
        extra: {
          welcome: true,
          stage: :j8
        }
      }
    )
  end

  def user_on_j11_after_registration
    notify(
      sender_id: @record,
      users: [@record],
      params: {
        object: "Déjà 10 jours",
        extra: {
          welcome: true,
          stage: :j11
        }
      }
    )
  end
end
