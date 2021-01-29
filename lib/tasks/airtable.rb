module Airtable
  DEFAULT_PATH = "#{Rails.root}/tmp"
  USERNAME = 'Airtable-backend'
  TEXT = "C’est l'heure de votre envoi de masse de SMS de suivi ! Importez ce csv dans vos Google Contacts pour ensuite utiliser votre app (DoItLater)"

  def self.upload klass, channel, dpts, stade, hors_zone: false
    ensure_directory_exist
    file = path dpts, stade
    object = Storage::Client.avatars.object(s3_path(klass, dpts, stade, hors_zone))

    CSV.open(file, 'w+', write_headers: true, headers: klass.headers) do |writer|
      klass.from_airtable(dpts, stade, hors_zone).each do |csv|
        writer << csv
      end
    end

    object.upload_file(file)

    to_slack klass, channel, object.public_url, dpts, stade, hors_zone
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

  def self.to_slack klass, channel, url, dpts, stade, hors_zone
    dpts = hors_zone ? ['Hors-Zone'] : dpts
    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      channel: channel,
      username: USERNAME,
      text: "Export du #{Date.today} pour #{klass.table_name} #{dpts}, #{stade}",
      attachments: [{
        text: TEXT,
      }, {
        text: url
      }]
    )
  end
end