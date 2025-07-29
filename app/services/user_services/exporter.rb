module UserServices
  class Exporter
    DEFAULT_PATH = "#{Rails.root}/tmp"
    FIELDS = %w{email phone address created_at}
    GROUP_TYPES = %w{outing action conversation}

    def initialize(user:)
      @user = user
    end

    def csv
      ensure_directory_exist

      file = path

      CSV.open(file, 'w+') do |writer|
        FIELDS.each do |field|
          writer << [I18n.t("activerecord.attributes.user.#{field}"), user.send(field)]
        end

        GROUP_TYPES.each do |group_type|
          t_group_type = I18n.t("activerecord.attributes.entourage.group_types.#{group_type}")

          entourages = Entourage.select('
            entourages.*,
            join_requests.created_at as join_request_created_at,
            chat_messages.content as chat_message_content,
            chat_messages.created_at as chat_message_created_at,
            users.email
          ')
          .joins(:join_requests)
          .joins("left join chat_messages on chat_messages.messageable_type = 'Entourage' and chat_messages.messageable_id = entourages.id")
          .joins('left join users on users.id = chat_messages.user_id')
          .where(["join_requests.user_id = ? and (chat_messages.user_id = ? or group_type = 'conversation')", user.id, user.id])
          .where(group_type: group_type)
          .order('entourages.id, chat_messages.created_at')

          if entourages.any?
            former_entourage_id = nil

            entourages.each do |entourage|
              writer << [''] unless entourage.id == former_entourage_id
              writer << [t_group_type, "Rejoint(e) le #{entourage.join_request_created_at}", (entourage.conversation? ? nil : entourage.title)] unless entourage.id == former_entourage_id
              writer << [entourage.email, entourage.chat_message_created_at, entourage.chat_message_content]

              former_entourage_id = entourage.id
            end
          end
        end
      end

      file
    end

    def export
      raise "User with phone #{user.phone} should have an email" unless user.email

      MemberMailer.user_export(user_id: user.id, recipient: user.email, cci: nil).deliver_later
    end

    private
    attr_reader :user

    def ensure_directory_exist
      Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
    end

    def path
      "#{DEFAULT_PATH}/user-#{user.phone}-#{Time.now.to_i}.csv"
    end
  end
end
