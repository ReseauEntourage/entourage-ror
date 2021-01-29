require 'tasks/airtable'

namespace :airtable do
  task :export_all do
    # Entoures, 92, 78
    Airtable.upload(Airtable::Entoures, '#respo-bo-92-78', [92, 78], '1.b Matché à compléter')
    Airtable.upload(Airtable::Entoures, '#respo-bo-92-78', [92, 78], '2.a Matché')
    Airtable.upload(Airtable::Entoures, '#respo-bo-92-78', [92, 78], '2.b bande lancée')
    # Entoureurs, 92, 78
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-92-78', [92, 78], '1. a Matché')
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-92-78', [92, 78], '1. b bande lancée')

    # Entoures, 75
    Airtable.upload(Airtable::Entoures, '#respo-bo-75', [75], '1.b Matché à compléter')
    Airtable.upload(Airtable::Entoures, '#respo-bo-75', [75], '2.a Matché')
    Airtable.upload(Airtable::Entoures, '#respo-bo-75', [75], '2.b bande lancée')
    # Entoureurs, 75
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-75', [75], '1. a Matché')
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-75', [75], '1. b bande lancée')

    # Entoures, 59
    Airtable.upload(Airtable::Entoures, '#respo-bo-59', [59], '1.b Matché à compléter')
    Airtable.upload(Airtable::Entoures, '#respo-bo-59', [59], '2.a Matché')
    Airtable.upload(Airtable::Entoures, '#respo-bo-59', [59], '2.b bande lancée')
    # Entoureurs, 59
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-59', [59], '1. a Matché')
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-59', [59], '1. b bande lancée')

    # Entoures, 69
    Airtable.upload(Airtable::Entoures, '#respo-bo-69', [69], '1.b Matché à compléter')
    Airtable.upload(Airtable::Entoures, '#respo-bo-69', [69], '2.a Matché')
    Airtable.upload(Airtable::Entoures, '#respo-bo-69', [69], '2.b bande lancée')
    # Entoureurs, 69
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-69', [69], '1. a Matché')
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-69', [69], '1. b bande lancée')

    # Entoures, 35
    Airtable.upload(Airtable::Entoures, '#respo-bo-35', [35], '1.b Matché à compléter')
    Airtable.upload(Airtable::Entoures, '#respo-bo-35', [35], '2.a Matché')
    Airtable.upload(Airtable::Entoures, '#respo-bo-35', [35], '2.b bande lancée')
    # Entoureurs, 35
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-35', [35], '1. a Matché')
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-35', [35], '1. b bande lancée')

    # Entoures, 93
    Airtable.upload(Airtable::Entoures, '#respo-bo-93', [93], '1.b Matché à compléter')
    Airtable.upload(Airtable::Entoures, '#respo-bo-93', [93], '2.a Matché')
    Airtable.upload(Airtable::Entoures, '#respo-bo-93', [93], '2.b bande lancée')
    # Entoureurs, 93
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-93', [93], '1. a Matché')
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-93', [93], '1. b bande lancée')

    # Entoures, 91, 94, 95
    Airtable.upload(Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '1.b Matché à compléter')
    Airtable.upload(Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '2.a Matché')
    Airtable.upload(Airtable::Entoures, '#respo-bo-idf', [91, 94, 95], '2.b bande lancée')
    # Entoureurs, 91, 94, 95
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-idf', [91, 94, 95], '1. a Matché')
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-idf', [91, 94, 95], '1. b bande lancée')

    # Entoures, HZ
    Airtable.upload(Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1.b Matché à compléter', hors_zone: true)
    Airtable.upload(Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '2.a Matché', hors_zone: true)
    Airtable.upload(Airtable::Entoures, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '2.b bande lancée', hors_zone: true)
    # Entoureurs, HZ
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1. a Matché', hors_zone: true)
    Airtable.upload(Airtable::Entoureurs, '#respo-bo-hz', [75,91,92,93,94,95,78,35,59,69], '1. b bande lancée', hors_zone: true)
  end
end
