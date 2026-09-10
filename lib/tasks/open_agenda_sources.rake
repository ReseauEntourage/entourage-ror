namespace :open_agenda_sources do
  desc 'Resynchronize every registered OpenAgenda source that has a UID (updates status + upcoming events cache)'
  task sync_all: :environment do
    OpenAgendaSource.with_uid.find_each do |source|
      source.sync!
      Rails.logger.info "type=open_agenda_source.sync source_id=#{source.id} name=#{source.name.inspect} status=#{source.status} upcoming=#{source.upcoming_events_count}"
    rescue => e
      Rails.logger.error "type=open_agenda_source.sync error: source_id=#{source.id} class=#{e.class} message=#{e.message.inspect}"
    end
  end

  # Seeded from the OpenAgenda piste re-audit (10/09/2026), AFTER creating a real OpenAgenda account
  # and public key (ENV['OPENAGENDA_PUBLIC_KEY']) and querying the real v2 API — every `agenda_uid`
  # and `upcoming_events_count` below reflects a real API response on that date, not a guess. Nothing
  # here is invented: agendas confirmed inactive (0 upcoming events) are seeded as such rather than
  # omitted, so nobody re-checks what's already been checked.
  desc 'Seed OpenAgenda sources identified and verified during the extended API audit'
  task seed_verified: :environment do
    [
      # --- Real, currently active neighborhood/précarité-adjacent agendas (small scale) ---
      {
        name: 'Centre Social Autogéré de la Parole errante',
        agenda_uid: 93288427,
        city: 'Montreuil (93)',
        notes: "Vérifié le 10/09/2026 via l'API réelle (clé publique) : le thème correspond parfaitement (« ateliers et permanences gratuites, ouvertes à toutes et tous », description officielle de l'agenda) — mais l'agenda est INACTIF : 0 événement à venir malgré 40 événements historiques (le dernier remonte à des années). Meilleur exemple thématique du corpus, mais actuellement mort."
      },
      {
        name: 'Centre social Unieux',
        agenda_uid: 95041552,
        city: 'Unieux (Loire)',
        notes: "Vérifié le 10/09/2026 : agenda réel (40 événements historiques dont AG, sorties) mais 0 événement à venir. Inactif."
      },
      {
        name: 'Maison de quartier Europe (Grande-Synthe)',
        agenda_uid: 80689685,
        city: 'Grande-Synthe (59)',
        notes: "Vérifié le 10/09/2026 : 0 événement à venir. L'ensemble du réseau des maisons de quartier de Grande-Synthe (Europe, Moulin, Courghain, Albeck, Saint-Jacques) est inactif sur OpenAgenda à cette date."
      },
      {
        name: 'Maison de quartier Saint-Jacques (Grande-Synthe)',
        agenda_uid: 80386981,
        city: 'Grande-Synthe (59)',
        notes: "Vérifié le 10/09/2026 : 0 événement à venir (voir note Maison de quartier Europe — réseau entier inactif)."
      },
      {
        name: 'Maison de quartier du Moulin (Grande-Synthe)',
        agenda_uid: 63573514,
        city: 'Grande-Synthe (59)',
        notes: "Vérifié le 10/09/2026 : 0 événement à venir."
      },
      {
        name: 'Maison de quartier du Courghain (Grande-Synthe)',
        agenda_uid: 19689130,
        city: 'Grande-Synthe (59)',
        notes: "Vérifié le 10/09/2026 : 0 événement à venir."
      },
      {
        name: "Maison de quartier de l'Albeck (Grande-Synthe)",
        agenda_uid: 19951712,
        city: 'Grande-Synthe (59)',
        notes: "Vérifié le 10/09/2026 : 0 événement à venir."
      },
      {
        name: 'Les quartiers ont la bougeotte',
        agenda_uid: 33419225,
        city: 'Tours / Indre-et-Loire',
        notes: "Vérifié le 10/09/2026 : 0 événement à venir — confirme l'hypothèse de contenu daté (été 2022) émise lors de l'audit documentaire, l'agenda est bien inactif."
      },

      # --- Real, currently ACTIVE metropolitan networks (the actual finding of this audit) ---
      {
        name: 'Nantes Métropole (agenda agrégateur)',
        agenda_uid: 82470621,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : agenda agrégateur RÉEL et ACTIF — 1716 événements à venir, alimenté par de nombreux agendas sources (chaque événement porte un champ originAgenda, ex. « Bibliothèque municipale de Nantes »). C'est un agenda municipal généraliste (culture, patrimoine, vie associative), pas exclusivement précarité/mixité : un filtrage est nécessaire. Champ personnalisé confirmé « nm-gratuit » (booléen, renseigné ponctuellement par l'organisateur — absent ne veut pas dire payant). Exemple confirmé gratuit et sur le thème : « Point Information Nantes Solidaire » (permanence du CCAS de la Ville de Nantes, nm-gratuit=true). Attention : la recherche plein texte de l'API donne des faux positifs (ex. « accueil de jour » remonte des spectacles de théâtre sans rapport) — filtrer sur des expressions exactes vérifiées, pas sur la pertinence du moteur de recherche."
      },
      {
        name: 'Agenda quartier Breil-Barberie (Nantes)',
        agenda_uid: 53319507,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 32 événements à venir, actif. Contenu mixte (patrimoine, vide-greniers) et solidaire (« Fête de l'alimentation et des solidarités » pour le 1er anniversaire de l'épicerie du Breil). Fait partie du réseau « Nantes Métropole »."
      },
      {
        name: 'Maison de quartier du Breil-Malville (Nantes)',
        agenda_uid: 45735769,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 5 événements à venir, actif et fortement pertinent — café des parents, ateliers créatifs parents/enfants, « PIXEL BREIL 2026 » explicitement décrit comme « gratuit et ouvert à toutes et tous ». Meilleur exemple concret et actif du corpus entier."
      },
      {
        name: 'Malakoff - Saint-Donatien (Nantes)',
        agenda_uid: 78820418,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 41 événements à venir, actif. Quartier prioritaire historique de Nantes."
      },
      {
        name: 'Dervallières - Zola (Nantes)',
        agenda_uid: 73292305,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 31 événements à venir, actif."
      },
      {
        name: 'Bellevue - Chantenay - Sainte-Anne (Nantes)',
        agenda_uid: 27316238,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 85 événements à venir, actif."
      },
      {
        name: 'Nantes Nord',
        agenda_uid: 20324272,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 84 événements à venir, actif."
      },
      {
        name: 'Nantes Sud',
        agenda_uid: 90707514,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 18 événements à venir, actif."
      },
      {
        name: 'Nantes Erdre',
        agenda_uid: 4856591,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 70 événements à venir, actif."
      },
      {
        name: 'Île de Nantes',
        agenda_uid: 2363867,
        city: 'Nantes',
        notes: "Vérifié le 10/09/2026 : 225 événements à venir, actif — le plus gros volume des agendas de quartier nantais testés."
      },
      {
        name: 'Rennes Métropole (agenda agrégateur)',
        agenda_uid: 20500020,
        city: 'Rennes',
        notes: "Vérifié le 10/09/2026 : agenda agrégateur RÉEL et ACTIF — 998 événements à venir. Même structure généraliste que Nantes Métropole (pas de champ nm-gratuit constaté ici, spécifique à Nantes) : nécessite aussi un filtrage. Correspond à l'un des trois territoires de l'audit iCal (Rennes), où aucun flux iCal n'avait été trouvé — piste alternative réelle pour cette ville."
      },
      {
        name: 'Rennes Quartiers Nord-Est',
        agenda_uid: 52138616,
        city: 'Rennes',
        notes: "Vérifié le 10/09/2026 : 18 événements à venir, actif."
      },
      {
        name: 'Rennes quartiers Ouest',
        agenda_uid: 30298725,
        city: 'Rennes',
        notes: "Vérifié le 10/09/2026 : 52 événements à venir, actif."
      },
      {
        name: 'Rennes La Bellangerais',
        agenda_uid: 19943336,
        city: 'Rennes',
        notes: "Vérifié le 10/09/2026 : 18 événements à venir, actif."
      },
      {
        name: 'Rennes Maurepas',
        agenda_uid: 85319813,
        city: 'Rennes',
        notes: "Vérifié le 10/09/2026 : 0 événement à venir. Inactif, malgré une présence réelle sur OpenAgenda — quartier pourtant identifié en géographie prioritaire."
      },
      {
        name: 'Rennes quartier Bréquigny',
        agenda_uid: 56041131,
        city: 'Rennes',
        notes: "Vérifié le 10/09/2026 : réponse API incohérente (total non numérique) lors du test — à revérifier manuellement avant d'en tirer une conclusion."
      },
      {
        name: 'Toulouse Métropole (agenda agrégateur)',
        agenda_uid: 50522407,
        city: 'Toulouse',
        notes: "Vérifié le 10/09/2026 : agenda agrégateur RÉEL et ACTIF — 1579 événements à venir. Même profil que Nantes/Rennes Métropole (généraliste, filtrage nécessaire). Non détaillé au niveau quartier par manque de temps — piste à approfondir si Toulouse devient une zone prioritaire."
      },
      {
        name: 'Bordeaux Métropole (agenda agrégateur)',
        agenda_uid: 83549053,
        city: 'Bordeaux',
        notes: "Vérifié le 10/09/2026 : agenda agrégateur RÉEL et ACTIF — 2268 événements à venir, le plus gros volume constaté. Même profil que les autres métropoles (généraliste, filtrage nécessaire). Non détaillé au niveau quartier par manque de temps."
      },
    ].each do |attrs|
      source = OpenAgendaSource.find_or_initialize_by(name: attrs[:name])
      source.assign_attributes(agenda_uid: attrs[:agenda_uid], city: attrs[:city], notes: attrs[:notes])
      source.status = 'not_checked' if source.new_record?
      source.save!
      Rails.logger.info "type=open_agenda_source.seed source_id=#{source.id} name=#{source.name.inspect} agenda_uid=#{source.agenda_uid}"
    end

    puts "Seeded #{OpenAgendaSource.count} total OpenAgenda sources " \
         "(#{OpenAgendaSource.with_uid.count} with a UID to sync). " \
         "Run `rake open_agenda_sources:sync_all` to (re)test them against the real API."
  end
end
