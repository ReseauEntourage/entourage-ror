module AirtableTask
  DEFAULT_PATH = "#{Rails.root}/tmp"
  USERNAME = 'Airtable-backend'
  TEXT = "C’est l'heure de votre envoi de masse de SMS de suivi ! Importez ce csv dans vos Google Contacts pour ensuite utiliser votre app (DoItLater)"

  def self.upload klass, channel, dpts, stade, hors_zone: false
    ensure_directory_exist
    file = path dpts, stade
    object = Storage::Client.csv.object(s3_path(klass, dpts, stade, hors_zone))

    CSV.open(file, 'w+', write_headers: true, headers: klass.headers) do |writer|
      klass.from_airtable(dpts, stade, hors_zone).each do |csv|
        writer << csv
      end
    end

    object.upload_file(file)

    to_slack klass, channel, object.key, dpts, stade, hors_zone
  end

  private

  def self.ensure_directory_exist
    Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
  end

  def self.path dpts, stade
    "#{DEFAULT_PATH}/#{Date.today}-#{stade.parameterize}-#{dpts.join('-')}-#{Time.now.to_i}.csv"
  end

  def self.s3_path klass, dpts, stade, hors_zone
    dpts = hors_zone ? ['hors-zone'] : dpts
    "airtable/#{Date.today}-#{klass.table_name.parameterize}-#{stade.parameterize}-#{dpts.join('-')}-#{Time.now.to_i}.csv"
  end

  def self.to_slack klass, channel, filename, dpts, stade, hors_zone
    dpts = hors_zone ? ['Hors-Zone'] : dpts
    callback_id = [:csv, klass, channel, filename, dpts, stade].join(':')

    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping({
      username: USERNAME,
      channel: channel,
      text: "Export du #{Date.today} pour #{klass.table_name} #{dpts}, #{stade}",
      attachments: [
        {
          color: "#3AA3E3",
          title: "Envoi de masse de SMS de suivi",
          text: "C'est l'heure de votre envoi de masse de SMS de suivi ! Importez ce csv dans vos Google Contacts pour ensuite utiliser votre app (DoItLater)",
          mrkdwn_in: [:text],
          callback_id: callback_id,
          actions: [
            {
              text:  "Télécharger",
              type:  :button,
              url: Rails.application.routes.url_helpers.admin_slack_csv_url(filename: filename, host: ENV['ADMIN_HOST']),
            },
          ]
        }
      ]
    })
  end
end
