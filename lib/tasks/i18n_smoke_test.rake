require 'tasks/i18n_smoke_test'

namespace :i18n do
  desc "Smoke-test des traductions (push, inapp, erreurs de formulaire, dates, smalltalks, "\
       "outing tasks, badges, mailers) pour toutes les langues. À lancer sur la recette/staging : "\
       "bundle exec rake i18n:smoke_test -- ne modifie rien en base, n'envoie aucun email/push réel."
  task smoke_test: :environment do
    I18nSmokeTest.run
  end
end
