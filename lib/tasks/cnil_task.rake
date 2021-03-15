require 'tasks/cnil_export'
require 'tasks/cnil_anonymize'

namespace :cnil_task do
  DEFAULT_CHANNEL = 'cnil'

  # @usage rake cnil_task:export PHONE="phone" CHANNEL="channel"
  task export: :environment do
    CnilExport::export(ENV['PHONE'], ENV['CHANNEL'] || DEFAULT_CHANNEL)
  end

  # @usage rake cnil_task:anonymize PHONE="phone" CHANNEL="channel"
  task anonymize: :environment do
    CnilAnonymize::anonymize(ENV['PHONE'])
  end
end
