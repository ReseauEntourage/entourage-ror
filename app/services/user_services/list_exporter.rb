module UserServices
  class ListExporter
    DEFAULT_PATH = "#{Rails.root}/tmp"
    FIELDS = %w{
      first_name
      last_name
      organization_name
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

    def initialize(users:)
      @users = users
    end

    def csv
      ensure_directory_exist

      file = path

      CSV.open(file, 'w+') do |writer|
        writer << FIELDS.map { |field| I18n.t("activerecord.attributes.user.#{field}") }

        users.each do |user|
          writer << FIELDS.map { |field| user.send(field) }
        end
      end

      file
    end

    private
    attr_reader :users

    def ensure_directory_exist
      Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
    end

    def path
      "#{DEFAULT_PATH}/users-#{Time.now.to_i}.csv"
    end
  end
end
