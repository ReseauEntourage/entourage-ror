module Atd
  class CsvImporter
    ATD_COMMUNICATION_DATE="10/02/2017"

    def initialize(csv:)
      @csv = csv
      @email_hashes = {}
      @phone_hashes = {}
    end

    def import
      set_entourage_user_hashes
      found_users = Set.new
      CSV.parse(csv) do |row|
        user_id = email_hashes[row["email"]] || phone_hashes[row["email"]]
        found_users.add({entourage_id: user_id, atd_id: row["id"]}) if user_id
      end
      generate_final_csv(found_users)
    end

    private
    attr_reader :csv, :email_hashes, :phone_hashes

    def generate_final_csv(found_users)
      CSV.open("tmp/tmp.csv", "wb") do |csv|
        csv << ["atd_id", "entourage_id", "email", "phone", "status"]

        found_users.each do |user_infos|
          user = User.find(user_infos[:entourage_id])
          csv << [user_infos[:atd_id],
                  user_infos[:entourage_id],
                  hash(user.email),
                  hash(user.phone),
                  status(user)]
        end
      end
    end

    def status(user)
      atd_date_start = Date.parse(ATD_COMMUNICATION_DATE)
      atd_date_end = atd_date_start+30.days
      if user.pro?
        "PRO"
      elsif user.created_at < atd_date_start
        "BEFORE_COMMUNICATION"
      elsif user.created_at > atd_date_start && user.created_at < atd_date_end
        "DURING_COMMUNICATION"
      elsif user.created_at > atd_date_end
        "AFTER_COMMUNICATION"
      end
    end

    def set_entourage_user_hashes
      User.all.find_each do |user|
        email_hashes[hash(user.email)] = user.id
        phone_hashes[hash(user.phone)] = user.id
      end
    end

    def hash(str)
      Digest::SHA1.hexdigest(str)
    end
  end
end