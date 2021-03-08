module CnilExport
  DEFAULT_PATH = "#{Rails.root}/tmp"
  USERNAME = 'Cnil-backend'
  FIELDS = %w{email phone address created_at}
  TEXT = "Un utilisateur a requis son effacement de l'application Entourage. Merci de lui transmettre ses informations personnelles que vous pourrez trouver dans le CSV"

  def self.export phone, channel
    return unless user = user_by_phone(phone)

    ensure_directory_exist
    file = path user
    object = Storage::Client.avatars.object(s3_path user)

    CSV.open(file, 'w+') do |writer|
      FIELDS.each do |field|
        writer << [user.send(field)]
      end
    end

    object.upload_file(file)

    to_slack user, channel, object.public_url
  rescue ActiveRecord::RecordNotFound => e
    puts "Could not find user. Please provide a valid phone number: #{e.message}"
  end

  private

  def self.user_by_phone(phone)
    User.find_by!(phone: Phone::PhoneBuilder.new(phone: phone).format)
  end

  def self.ensure_directory_exist
    Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
  end

  def self.path user
    "#{DEFAULT_PATH}/#{Date.today}-#{user.phone}-#{user.id}-#{Time.now.to_i}.csv"
  end

  def self.s3_path user
    "cnil/#{Date.today}-#{user.phone}-#{user.id}-#{Time.now.to_i}.csv"
  end

  def self.to_slack user, channel, url
    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
      channel: channel,
      username: USERNAME,
      text: "Export du #{Date.today} pour #{user.phone}, #{user.email}",
      attachments: [{
        text: TEXT,
      }, {
        text: url
      }]
    )
  end
end