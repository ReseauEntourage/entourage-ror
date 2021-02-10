require 'tasks/airtable_task'
# require 'app/services/airtable/entoures'
# require 'app/services/airtable/entoureurs'

namespace :airtable_task do
  task :export_test do
    AirtableTask.upload(::Airtable::Entoureurs, '#test-nicolas', [59], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-92-78', [92, 78], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-75', [75], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-59', [59], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-69', [69], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-35', [35], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-93', [93], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-idf', [91, 94, 95], '1. b Bande lancée')
    # AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1. b Bande lancée', hors_zone: true)
  end

  task :export_all do
    # Entoures, 92, 78
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-92-78', [92, 78], '1.b Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-92-78', [92, 78], '2.a Matché')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-92-78', [92, 78], '2.b bande lancée')
    # Entoureurs, 92, 78
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-92-78', [92, 78], '1. a Matché')
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-92-78', [92, 78], '1. b Bande lancée')

    # Entoures, 75
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-75', [75], '1.b Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-75', [75], '2.a Matché')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-75', [75], '2.b bande lancée')
    # Entoureurs, 75
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-75', [75], '1. a Matché')
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-75', [75], '1. b Bande lancée')

    # Entoures, 59
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-59', [59], '1.b Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-59', [59], '2.a Matché')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-59', [59], '2.b bande lancée')
    # Entoureurs, 59
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-59', [59], '1. a Matché')
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-59', [59], '1. b Bande lancée')

    # Entoures, 69
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-69', [69], '1.b Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-69', [69], '2.a Matché')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-69', [69], '2.b bande lancée')
    # Entoureurs, 69
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-69', [69], '1. a Matché')
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-69', [69], '1. b Bande lancée')

    # Entoures, 35
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-35', [35], '1.b Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-35', [35], '2.a Matché')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-35', [35], '2.b bande lancée')
    # Entoureurs, 35
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-35', [35], '1. a Matché')
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-35', [35], '1. b Bande lancée')

    # Entoures, 93
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-93', [93], '1.b Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-93', [93], '2.a Matché')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-93', [93], '2.b bande lancée')
    # Entoureurs, 93
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-93', [93], '1. a Matché')
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-93', [93], '1. b Bande lancée')

    # Entoures, 91, 94, 95
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '1.b Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '2.a Matché')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '2.b bande lancée')
    # Entoureurs, 91, 94, 95
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-idf', [91, 94, 95], '1. a Matché')
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-idf', [91, 94, 95], '1. b Bande lancée')

    # Entoures, HZ
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1.b Matché à compléter', hors_zone: true)
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '2.a Matché', hors_zone: true)
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '2.b bande lancée', hors_zone: true)
    # Entoureurs, HZ
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1. a Matché', hors_zone: true)
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1. b Bande lancée', hors_zone: true)
  end
end
