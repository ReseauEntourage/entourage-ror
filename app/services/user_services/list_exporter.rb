module UserServices
  class ListExporter
    DEFAULT_PATH = "#{Rails.root}/tmp"
    FIELDS = %w{
      first_name
      last_name
      created_at
      last_sign_in_at
      goal
      targeting_profile
      email
      phone
      postal_code
      engaged?
      validation_status
      deleted
    }

    FULL_FIELDS = FIELDS + %w{
      action_creations_count
      action_participations_count
      outing_participations_count
      conversation_participations_count
    }

    SLACK_CHANNEL = '#test-nicolas'

    def initialize(users:)
      @users = users
    end

    def csv
      file = UserServices::ListExporter.get_file

      CSV.open(file, 'w+') do |writer|
        writer << FIELDS.map { |field| I18n.t("activerecord.attributes.user.#{field}") }

        users.each do |user|
          writer << FIELDS.map { |field| user.send(field) }
        end
      end

      file
    end

    class << self
      def export user_ids
        file = path

        CSV.open(file, 'w+') do |writer|
          writer << FULL_FIELDS.map { |field| I18n.t("activerecord.attributes.user.#{field}") }

          user_ids.each do |user_id|
            user = User.find(user_id)
            writer << FULL_FIELDS.map { |field| user.send(field) }
          end
        end

        file
      end

      def get_file
        ensure_directory_exist
        path
      end

      def ensure_directory_exist
        Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
      end

      def path
        "#{DEFAULT_PATH}/users-#{Time.now.to_i}.csv"
      end

      def to_slack csv
        return if ENV['SLACK_WEBHOOK_URL'].blank?

        Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
          channel: SLACK_CHANNEL,
          username: ENV['SMS_SENDER_NAME'],
          text: CSV.read(csv).to_s
        )

        return 'Ok'
      end
    end

    private

    attr_reader :users
  end
end
