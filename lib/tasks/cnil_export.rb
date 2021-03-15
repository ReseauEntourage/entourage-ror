module CnilExport

  def self.export phone, channel
    return unless user = user_by_phone(phone)

    file = UserServices::Exporter.new(user: user).csv

    object = Storage::Client.avatars.object(s3_path user)
    object.upload_file(file)

    to_slack user, channel, object.public_url
  rescue ActiveRecord::RecordNotFound => e
    puts "Could not find user. Please provide a valid phone number: #{e.message}"
  end

  private

  def self.user_by_phone(phone)
    User.find_by!(phone: Phone::PhoneBuilder.new(phone: phone).format)
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