require 'tasks/airtable_task'

namespace :airtable_task do
  task export_test: :environment do
    AirtableTask.upload(::Airtable::Entoureurs, '#test-nicolas', [59], '1. Matché')
  end

  task export_all: :environment do
    # Entoures, 92, 78
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-92-78', [92, 78], '1.Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-92-78', [92, 78], '2. Matché')
    # Entoureurs, 92, 78
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-92-78', [92, 78], '1. Matché')

    # Entoures, 75
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-75', [75], '1.Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-75', [75], '2. Matché')
    # Entoureurs, 75
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-75', [75], '1. Matché')

    # Entoures, 59
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-59', [59], '1.Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-59', [59], '2. Matché')
    # Entoureurs, 59
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-59', [59], '1. Matché')

    # Entoures, 69
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-69', [69], '1.Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-69', [69], '2. Matché')
    # Entoureurs, 69
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-69', [69], '1. Matché')

    # Entoures, 35
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-35', [35], '1.Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-35', [35], '2. Matché')
    # Entoureurs, 35
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-35', [35], '1. Matché')

    # Entoures, 93
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-93', [93], '1.Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-93', [93], '2. Matché')
    # Entoureurs, 93
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-93', [93], '1. Matché')

    # Entoures, 91, 94, 95
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '1.Matché à compléter')
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '2. Matché')
    # Entoureurs, 91, 94, 95
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-idf', [91, 94, 95], '1. Matché')

    # Entoures, HZ
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1.Matché à compléter', hors_zone: true)
    AirtableTask.upload(::Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '2. Matché', hors_zone: true)
    # Entoureurs, HZ
    AirtableTask.upload(::Airtable::Entoureurs, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1. Matché', hors_zone: true)
  end
end
