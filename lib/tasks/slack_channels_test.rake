namespace :slack do
  desc "Ping each Slack channel configured in SLACK_APP_WEBHOOKS to confirm webhook routing works"
  task :test_moderation_channels, [:department] => :environment do |_, args|
    raise "SLACK_APP_WEBHOOKS is not set" if ENV['SLACK_APP_WEBHOOKS'].blank?

    config = JSON.parse(ENV['SLACK_APP_WEBHOOKS'])
    prefix = config.fetch('prefix')

    departments =
      if args[:department].present?
        [args[:department]]
      else
        (config.keys - ['prefix', 'default']) | ['default']
      end

    # group departments by channel suffix so each channel is only pinged once
    by_suffix = departments.group_by { |department| config[department] || config['default'] }

    results = by_suffix.map do |suffix, deps|
      region = ModerationServices::Region.for_department(deps.reject { |d| d == 'default' }.first)
      label = deps.include?('default') ? 'default' : "#{deps.join(', ')} (#{region || 'no region'})"

      begin
        url = prefix + suffix
        text = "🧪 Test de routage modération — départements : #{label} — #{Time.zone.now.strftime('%d/%m/%Y %H:%M:%S')}"

        response = Slack::Notifier.new(url).ping(text: text)
        ok = response.is_a?(Array) ? response.all? { |r| r.code.to_i == 200 } : response.code.to_i == 200

        { label: label, suffix: suffix, ok: ok }
      rescue => e
        { label: label, suffix: suffix, ok: false, error: e.message }
      end
    end

    puts "\nRésultat des tests d'envoi Slack :\n\n"
    results.each do |result|
      status = result[:ok] ? "OK" : "ECHEC#{" (#{result[:error]})" if result[:error]}"
      puts "  [#{status}] #{result[:label]} -> suffix=#{result[:suffix]}"
    end

    failures = results.reject { |r| r[:ok] }
    if failures.any?
      raise "#{failures.size} channel(s) did not receive the test message"
    else
      puts "\nTous les channels ont bien reçu le message de test."
    end
  end
end
