module SlackServices
  class SignalRackAttack < Notifier
    def initialize ip:, attack_type:
      @ip = ip
      @attack_type = attack_type
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      { text: "Attaque de type #{@attack_type} détectée à #{Time.zone.now} sur l'ip #{@ip}" }
    end

    def payload_adds
      {
        username: "Attaque détectée",
        channel: "test-nicolas",
      }
    end
  end
end
