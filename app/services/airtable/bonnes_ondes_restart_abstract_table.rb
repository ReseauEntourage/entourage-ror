Airrecord.api_key = ENV['AIRTABLE_API_KEY']

module Airtable
  class BonnesOndesRestartAbstractTable < Airrecord::Table
    DEFAULT_PATH = "#{Rails.root}/tmp"
    USERNAME = 'Airtable-backend'

    self.base_key = ENV['AIRTABLE_BONNES_ONDES_RESTART']

    def self.by_dpt_and_stade dpts, stade
      dpts = dpts.map do |dpt|
        "{Dépt} = '#{dpt}'"
      end.join(', ')

      all(filter: "AND({Stade ?} = '#{stade}', OR(#{dpts}))")
    end

    def self.from_airtable dpts, stade
      # map = self.map
      # by_dpt_and_stade(dpt, stade).map(&:fields).map do |entoure|
      #   entoure.slice(map[:mobile], map[:email], map[:lastname], map[:firstname])
      # end.map(&:values)
      by_dpt_and_stade(dpts, stade).map(&:fields).map(&:values)
    end

    def self.to_slack channel, url, dpts, stade
      Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
        channel: channel,
        username: USERNAME,
        text: "Export du #{Date.today} pour le scope #{dpts}, #{stade}",
        attachments: [{
          text: url
        }]
      )
    end

    def self.upload channel, dpts, stade
      ensure_directory_exist
      file = path dpts

      CSV.open(file, 'w+', write_headers: true, headers: headers) do |writer|
        from_airtable(dpts, stade).each do |csv|
          writer << csv
        end
      end

      Storage::Client.csv.upload(file: file, key: file)
      url = Storage::Client.csv.url_for(key: file)

      to_slack channel, url, dpts, stade
    end

    private

    def self.ensure_directory_exist
      Dir.mkdir(DEFAULT_PATH) unless Dir.exist?(DEFAULT_PATH)
    end

    def self.path dpts
      "#{DEFAULT_PATH}/#{Date.today}-#{dpts.join('-')}-#{Time.now.to_i}.csv"
    end
  end
end
