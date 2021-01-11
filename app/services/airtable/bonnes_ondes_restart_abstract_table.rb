Airrecord.api_key = ENV['AIRTABLE_API_KEY']

module Airtable
  class BonnesOndesRestartAbstractTable < Airrecord::Table
    DEFAULT_PATH = "#{Rails.root}/tmp"
    USERNAME = 'Airtable-backend'

    self.base_key = ENV['AIRTABLE_BONNES_ONDES_RESTART']

    def self.by_dpt_and_stade dpt, stade
      all(filter: "AND({Stade ?} = '#{stade}', {Dépt} = '#{dpt}')")
    end

    def self.from_airtable dpt, stade
      # map = self.map
      # by_dpt_and_stade(dpt, stade).map(&:fields).map do |entoure|
      #   entoure.slice(map[:mobile], map[:email], map[:lastname], map[:firstname])
      # end.map(&:values)
      by_dpt_and_stade(dpt, stade).map(&:fields).map(&:values)
    end

    def self.to_slack channel, url, dpt, stade
      Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
        channel: channel,
        username: USERNAME,
        text: "Export du #{Date.today} pour le scope #{dpt}, #{stade}",
        attachments: [{
          text: url
        }]
      )
    end

    def self.upload channel, dpt, stade
      # Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)

      file = "#{DEFAULT_PATH}/#{Date.today}-#{dpt}-#{Time.now.to_i}.csv"

      CSV.open(file, 'w+', write_headers: true, headers: self.headers) do |writer|
        from_airtable(dpt, stade).each do |csv|
          writer << csv
        end
      end

      Storage::Client.csv.upload(file: file, key: file)
      url = Storage::Client.csv.url_for(key: file)

      to_slack channel, url, dpt, stade
    end
  end
end
