module UserServices
  class Exporter
    DEFAULT_PATH = "#{Rails.root}/tmp"
    FIELDS = %w{email phone address created_at}
    TEXT = "Un utilisateur a requis son effacement de l'application Entourage. Merci de lui transmettre ses informations personnelles que vous pourrez trouver dans le CSV"

    def initialize(user:)
      @user = user
    end

    def csv
      ensure_directory_exist

      file = path

      CSV.open(file, 'w+') do |writer|
        FIELDS.each do |field|
          writer << [user.send(field)]
        end
      end

      file
    end

    def export cci:
      raise "User with phone #{user.phone} should have an email" unless user.email
      raise "User with phone #{cci.phone} should have an email" unless cci.email

      MemberMailer.user_export(csv: csv, recipient: user.email, cci: cci.email).deliver_later
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
