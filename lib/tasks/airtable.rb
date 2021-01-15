module Airtable
  DEFAULT_PATH = "#{Rails.root}/tmp"
  USERNAME = 'Airtable-backend'
  TEXT = "C’est l’heure de votre envoi de masse de SMS de suivi! Importez ce csv dans vos Google Contacts pour ensuite utiliser votre app (DoItLater)"

  def self.upload channel, dpts, stade
    ensure_directory_exist
    file = path dpts
    object = Storage::Client.avatars.object(s3_path dpts)

    CSV.open(file, 'w+', write_headers: true, headers: Airtable::Entoures.headers) do |writer|
      Airtable::Entoures.from_airtable(dpts, stade).each do |csv|
        writer << csv
      end
    end

    object.upload_file(file)

    to_slack channel, object.public_url, dpts, stade
  end

  private

  def self.ensure_directory_exist
    Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
  end

  def self.path dpts
    "#{DEFAULT_PATH}/#{Date.today}-#{dpts.join('-')}-#{Time.now.to_i}.csv"
  end

  def self.s3_path dpts
    "airtable/#{Date.today}-#{dpts.join('-')}-#{Time.now.to_i}.csv"
  end

  def self.to_slack channel, url, dpts, stade
    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      channel: channel,
      username: USERNAME,
      text: "Export du #{Date.today} pour le scope #{dpts}, #{stade}",
      attachments: [{
        text: TEXT,
      }, {
        text: url
      }]
    )
  end
end