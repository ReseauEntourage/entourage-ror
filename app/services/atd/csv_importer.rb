module Atd
  class CsvImporter
    ATD_COMMUNICATION_DATE="10/02/2017"

    def initialize(csv:)
      @csv = csv
      @email_hashes = {}
      @phone_hashes = {}
      @result_file = Tempfile.new
    end

    def match
      set_entourage_user_hashes
      CSV.parse(csv, {headers: true, col_sep: ","}) do |row|
        user_id = email_hashes[row["mail_hash"]] || phone_hashes[row["tel_hash"]]
        AtdUser.create(atd_id: row["id_physique"], user_id: user_id, mail_hash: row["mail_hash"], tel_hash: row["tel_hash"])
        if user_id
          Rails.logger.info "Found atd user : #{user_id}"
          User.find(user_id).update(atd_friend: true)
        end
      end
    end

    private
    attr_reader :csv, :result_file
    attr_accessor :email_hashes, :phone_hashes

    # def generate_final_csv(found_users)
    #   CSV.open(result_file, "wb") do |csv|
    #     csv << ["atd_id", "entourage_id", "email", "phone", "status"]
    #
    #     found_users.each do |user_infos|
    #       user = User.find(user_infos[:entourage_id])
    #       csv << [user_infos[:atd_id],
    #               user_infos[:entourage_id],
    #               hash(user.email),
    #               hash(user.phone),
    #               status(user)]
    #     end
    #   end
    # end

    # def status(user)
    #   atd_date_start = Date.parse(ATD_COMMUNICATION_DATE)
    #   atd_date_end = atd_date_start+30.days
    #   if user.pro?
    #     "PRO"
    #   elsif user.created_at < atd_date_start
    #     "BEFORE_COMMUNICATION"
    #   elsif user.created_at > atd_date_start && user.created_at < atd_date_end
    #     "DURING_COMMUNICATION"
    #   elsif user.created_at > atd_date_end
    #     "AFTER_COMMUNICATION"
    #   end
    # end

    def set_entourage_user_hashes
      User.find_each do |user|
        email_hashes[hash(user.email)] = user.id
        phone_hashes[hash(user.phone)] = user.id
      end
    end

    def hash(str)
      return unless str
      Digest::SHA1.hexdigest(str)
    end

    def atd_partner
      @atd_partner ||= Partner.first
    end
  end
end
