module PoiServices
  class SoliguideFormatter
    # @todo add unit tests
    # @todo refactor: get specific formatter for services_all, location, entity, languages
    def self.format poi
      return nil unless poi
      return nil unless poi['entity']
      return nil unless poi['position']
      return nil unless poi['position']['location']
      return nil unless poi['services_all']

      source_categories = poi['services_all'].map { |service| service['categorie'] }
      phones = poi['entity']['phones'].presence
      languages = poi['languages'] || []

      {
        uuid: "s#{poi['lieu_id']}",
        source_id: poi['lieu_id'],
        source: :soliguide,
        source_url: "https://soliguide.fr/fiche/#{poi['seo_url']}",
        name: format_title(poi['name'], poi['entity']['name']),
        description: format_description(poi['description']),
        longitude: poi['position']['location']['coordinates'][0].round(6),
        latitude: poi['position']['location']['coordinates'][1].round(6),
        address: poi['position']['adresse'].presence,
        postal_code: poi['position']['codePostal'].presence,
        phone: format_phones(phones).first,
        phones: format_phones(phones).join(', '),
        website: poi['entity']['website'].presence,
        email:poi['entity']['mail'].presence,
        audience: format_audience(poi['publics'], poi['modalities']),
        category_ids: format_category_ids(poi),
        source_category_id: source_categories.compact.first,
        source_category_ids: source_categories.compact.uniq,
        hours: format_hours(poi['newhours']),
        languages: languages.map { |l| ISO_LANGS[l.to_sym] }.compact.join(', ')
      }
    end

    def self.format_short poi
      return nil unless poi

      category_ids = format_category_ids(poi)

      {
        uuid: "s#{poi['lieu_id']}",
        source_id: poi['lieu_id'],
        name: format_title(poi['name'], poi['entity']['name']),
        longitude: poi['position']['location']['coordinates'][0].round(6),
        latitude: poi['position']['location']['coordinates'][1].round(6),
        address: poi['position']['adresse'],
        postal_code: poi['position']['codePostal'].presence,
        phone: poi['entity']['phone'],
        category_id: category_ids.any? ? category_ids[0] : 0,
        partner_id: nil
      }
    end

    def self.format_audience publics, modalities
      (format_publics(publics) + format_modalities(modalities) + format_other_modalities(modalities)).join("\n")
    end

    def self.format_category_ids poi
      return [] unless poi['services_all']

      poi['services_all'].map do |service|
        service['categorie']
      end.map do |category_id|
        CATEGORIES_EQUIVALENTS[category_id]
      end.compact.uniq
    end

    # "publics": {
    #   "age": {
    #     "max": Number,
    #     "min": Number
    #   },
    #   "accueil": Number,
    #   "description": String,
    #   "administrative": [String],
    #   "familialle": [String],
    #   "gender": [String],
    #   "other": [String]
    # },
    def self.format_publics publics
      return [] unless publics

      sentences = []

      accueil = "Accueil #{format_accueil publics['accueil']}"

      sentences << if publics['accueil'] == 0
        accueil
      else
        "#{accueil} : #{(
          format_age(publics['age']) +
          format_familialle(publics['familialle']) +
          format_other(publics['other'])
        ).compact.join(', ')}"
      end

      if format_administrative(publics['administrative'])
        sentences << "Accueil : %s" % format_administrative(publics['administrative'])
      end

      if publics['description'].present?
        sentences << "Autres informations importantes : %s" % publics['description']
      end

      sentences.compact
    end

    def self.format_accueil accueil
      return "préférentiel" if accueil == 1
      return "exclusif" if accueil == 2

      "inconditionnel"
    end

    def self.format_age age
      return [] unless age

      min = age['min'].presence
      max = age['max'].presence

      return [] unless min || max

      return ["mineurs (-18 ans)"] if max && max <= 18
      return ["adultes uniquement"] if min == 18 && max == 99
      return ["dès %s ans" % min] if min.present? && max.nil?
      return [] if min == 0 && max == 99 # tous ages
      return ["de %s à %s ans" % [min, max]] if min.present? && max.present?

      []
    end

    def self.format_familialle familialle
      # isolated : personne isolée
      # family : famille
      # couple : couple
      # pregnant : femme enceinte
      return [] unless familialle.present?
      return [] if familialle.sort == ['isolated', 'family', 'couple', 'pregnant'].sort

      familialle.map do |term|
        case term
        when 'isolated' then 'Personne isolée'
        when 'family' then 'Famille'
        when 'couple' then 'Couple'
        when 'pregnant' then 'Femme enceinte'
        end
      end
    end

    def self.format_administrative administrative
      return nil unless administrative.present?
      return nil if administrative.sort == ["asylum", "refugee", "regular", "undocumented"].sort

      # regular : personne en situation régulière
      # asylum : personne demandeur⋅euse d'asile
      # refugee : personne avec le statut de réfugié
      # undocumented : personne sans papier

      situations = []
      situations << "en situation régulière" if administrative.include?('regular')
      situations << "sans papiers"         if administrative.include?('undocumented')
      situations << "demandeurs d'asile"   if administrative.include?('asylum')
      situations << "réfugiés"             if administrative.include?('refugee')

      "personnes #{situations.join(', ')}"
    end

    def self.format_other other
      return [] unless other.present?
      return [] if other.sort == ['violence', 'addiction', 'handicap', 'lgbt+', 'hiv', 'prostitution', 'prison', 'student'].sort

      # violence : personne victime de violence
      # addiction : personne en situation d'addiction
      # handicap : personne en situation de handicap
      # lgbt+ : personne appartenant aux communautés LGBT+
      # hiv : personne porteuse du VIH
      # prostitution : travailleur/travailleuse du sexe
      # prison : personne sortant de prison
      # student : personne étudiante

      others = []
      others << "victime de violence" if other.include?('violence')
      others << "en situation d'addiction" if other.include?('addiction')
      others << "en situation de handicap" if other.include?('handicap')
      others << "appartenant aux communautés LGBT+" if other.include?('lgbt+')
      others << "porteuse du VIH" if other.include?('hiv')
      others << "travailleur(euse) du sexe" if other.include?('prostitution')
      others << "sortant de prison" if other.include?('prison')
      others << "étudiant(e)" if other.include?('student')

      others
    end

    def self.format_modalities modalities
      return [] unless modalities
      return ["Accueil sans rendez-vous"] if modalities['inconditionnel'] == true

      sentences = []

      #  - modalities.inconditionnel qui définit si une structure n'a pas de conditions d'accès spécifiques. Si modalities.inconditionnel est à true, alors les autres données ne sont pas à prendre en compte (et sont à false de manière générale) ;
      #  - modalities.appointment.checked qui définit si une structure est sur RDV ou pas ;
      #  - modalities.inscription.checked qui définit si une structure est sur inscription ou pas ;
      #  - modalities.orientation.checked qui définit si une structure est sur orientation ou pas ;
      # Les 3 dernières données (appointment, inscription, orientation) sont cumulables (une structure peut être à la fois sur RDV et sur orientation) mais pas avec inconditionnel

      if modalities['appointment'] && modalities['appointment']['checked'] == true
        sentences << "Sur rendez-vous (#{modalities['appointment']['precisions']})"
      end

      if modalities['inscription'] && modalities['inscription']['checked'] == true
        sentences << "Sur inscription (#{modalities['inscription']['precisions']})"
      end

      if modalities['orientation'] && modalities['orientation']['checked'] == true
        sentences << "Sur orientation (#{modalities['orientation']['precisions']})"
      end

      sentences << format_animal(modalities['animal'])

      sentences.compact
    end

    def self.format_animal animal
      return nil unless animal.present?
      return nil if animal['checked'].nil?
      return "Animaux non autorisés" unless animal['checked']

      "Animaux autorisés"
    end

    def self.format_other_modalities modalities
      return [] unless modalities.present?
      return [] unless modalities['other'].present?

      ["Autres précisions : #{modalities['other']}"]
    end

    def self.format_hours hours
      return [] unless hours

      hours.map do |day, hours|
        next unless hours.present?

        day = {
          'monday'    => 'Lun',
          'tuesday'   => 'Mar',
          'wednesday' => 'Mer',
          'thursday'  => 'Jeu',
          'friday'    => 'Ven',
          'saturday'  => 'Sam',
          'sunday'    => 'Dim',
        }[day]

        if hours['timeslot'].blank?
          hours = 'Fermé'
        else
          hours = hours['timeslot'].map do |timeslot|
            format_hour_range(timeslot['start'], timeslot['end'])
          end.compact.join(' - ')
        end

        "#{day} : #{hours}"
      end.compact.join("\n")
    end

    def self.format_hour_range left, right
      bounds = [left, right].map { |bound| format_hour(bound) }
      return if bounds.any?(&:nil?)
      bounds.join(' à ')
    end

    def self.format_hour seconds
      return if seconds.nil? || seconds == -1
      hours = seconds / 100
      minutes = seconds % 100
      "%dh%02d" % [hours, minutes]
    end

    def self.format_title place_name, entity_name
      place_name  = place_name.presence
      entity_name = entity_name.presence


      # if more than half of the entity name's words are in the place name,
      # ignore the entity name
      place_name_words  = extract_words(place_name )
      entity_name_words = extract_words(entity_name)

      reused_words = place_name_words & entity_name_words

      if reused_words.count.to_f / entity_name_words.count > 0.5
        entity_name = nil
      end


      [place_name, entity_name].compact.join(' - ')
    end

    def self.format_description string
      Nokogiri::HTML(string).text
        .gsub(/\n\n+/, "\n\n") # Never leave more than 2 consecutive newlines.
        .strip                 # Strip leading and trailing whitespace.
    end

    def self.format_phones phones
      return [] unless phones.presence

      phones.pluck('phoneNumber')
    end

    def self.extract_words string
      return [] if string.nil?
      # consecutive alphanumeric characters and/or point (".", for abbreviations)
      # downcased to make comparison case-insentitive
      # 3-and-less-letter words excluded as they are mostly "stop words"
      string.downcase.scan(/[[:alnum:]\.]+/).select { |word| word.length >= 4 }
    end

    def self.categories_from_entourage entourage_category
      return nil unless entourage_category
      return nil unless CATEGORIES_EQUIVALENTS.values.include?(entourage_category)

      CATEGORIES_EQUIVALENTS.find_all {|_, value|
        value == entourage_category
      }.map(&:first)
    end

    def self.group_by_top_category categories
      groups = {}
      categories.each do |category|
        top_category = category - category % 100
        groups[top_category] ||= []
        groups[top_category] << category
      end
      groups
    end

    CATEGORIES_EQUIVALENTS = {
      # Santé (toutes)  Se soigner
      100 => 3, # SANTE
      101 => 3, # ADDICTION
      102 => 3, # DEPISTAGE
      103 => 3, # PSYCHOLOGIE
      104 => 3, # SOINS_ENFANTS
      105 => 3, # GENERALISTE
      106 => 3, # DENTAIRE
      107 => 3, # PLANIFICATION
      109 => 3, # VACCINATION
      110 => 3, # INFIRMERIE
      111 => 3, # VETERINAIRE

      # Formation et emploi (toutes)  Se réinsérer
      200 => 7, # FORMATION_EMPLOI
      201 => 7, # FORMATION_NUMERIQUE
      202 => 7, # FORMATION_FRANCAIS
      203 => 7, # ACCOMPAGNEMENT_EMPLOI
      205 => 7, # CHANTIER_DE_REINSERTION
      206 => 7, # SOUTIEN_SCOLAIRE

      # Hygiène et bien-être  Hygiène et bien-être  S'occuper de soi
      300 => 6, # HYGIENE

      # Hygiène et bien-être  Douche  Douche
      301 => 42, # DOUCHE

      # Hygiène et bien-être  Laverie Laverie
      302 => 43, # LAVERIE

      # Hygiène et bien-être  Bien-être S'occuper de soi
      303 => 6, # BIEN_ETRE

      # Hygiène et bien-être  Toilettes Toilettes
      304 => 40, # TOILETTES

      # Hygiène et bien-être  Protections périodiques S'occuper de soi
      305 => 6, # PROTECTIONS_PERIODIQUES

      # Hygiène et bien-être  Masques Se soigner
      306 => 3, # MASQUES

      # Conseil -> S'orienter
      400 => 5, # CONSEIL

      # Conseil Conseil logement  Se loger
      401 => 2, # CONSEIL_LOGEMENT

      # Conseil -> S'orienter
      402 => 5, # PERMANENCE_JURIDIQUE
      403 => 5, # DOMICILIATION
      404 => 5, # ACCOMPAGNEMENT_SOCIAL
      405 => 5, # ECRIVAIN_PUBLIC
      406 => 5, # CONSEIL_HANDICAP
      407 => 5, # CONSEIL_ADMINISTRATIF

      # Technologie (toutes)  S'orienter
      500 => 5, # TECHNOLOGIE
      501 => 5, # ORDINATEUR
      502 => 5, # WIFI
      503 => 5, # PRISE
      504 => 5, # TELEPHONE
      505 => 5, # NUMERISATION

      # Alimentation (toutes sauf Fontaine)  Se nourrir
      600 => 1, # ALIMENTATION
      601 => 1, # DISTRIBUTION_ALIMENTAIRE
      602 => 1, # RESTAURATION_ASSISE
      603 => 1, # COLIS_ALIMENTAIRE
      604 => 1, # EPICERIE_SOCIALE

      # Alimentation  Fontaine  Fontaines à eau
      605 => 41, # FONTAINE

      # Accueil Accueil S'orienter
      700 => 5, # ACCUEIL

      # Accueil Accueil de jour S'orienter
      701 => 5, # ACCUEIL_JOUR

      # Accueil Espace de repos S'occuper de soi
      702 => 6,

      # Accueil Garde d'enfants Se réinsérer
      703 => 7,

      # Accueil Espace famille S'occuper de soi
      704 => 6,

      # Accueil Point d'information Se réinsérer
      705 => 7,

      # Activités (Toutes)  S'occuper de soi
      800 => 6, # ACTIVITES
      801 => 6, # ACTIVITES_SPORTIVES
      802 => 6, # MUSEE
      803 => 6, # BIBLIOTHEQUE
      804 => 6, # ACTIVITES_DIVERSES

      # Matériel -> S'occuper de soi
      900 => 6, # MATERIEL

      # Bagagerie -> Bagageries
      901 => 63, # BAGAGERIE

      # Matériel -> S'occuper de soi
      902 => 6, # BOUTIQUE_SOLIDAIRE

      # Matériel  Vêtements Vêtements
      903 => 61, # VETEMENTS

      # Matériel -> S'occuper de soi
      904 => 6, # ANIMAUX

      # Spécialistes  (Toutes)  Se soigner
      1100 => 3, # SPECIALISTES
      1101 => 3, # ALLERGOLOGIE
      1102 => 3, # CARDIOLOGIE
      1103 => 3, # DERMATOLOGIE
      1104 => 3, # ECHOGRAPHIE
      1105 => 3, # ENDOCRINOLOGIE
      1106 => 3, # GASTRO_ENTEROLOGIE
      1107 => 3, # GYNECOLOGIE
      1108 => 3, # KINESITHERAPIE
      1109 => 3, # MAMMOGRAPHIE
      1110 => 3, # OPHTALMOLOGIE
      1111 => 3, # OTO_RHINO_LARYNGOLOGIE
      1112 => 3, # NUTRITION
      1113 => 3, # PEDICURE
      1114 => 3, # PHLEBOLOGIE
      1115 => 3, # PNEUMOLOGIE
      1116 => 3, # RADIOLOGIE
      1117 => 3, # RHUMATOLOGIE
      1118 => 3, # UROLOGIE
      1119 => 3, # ORTHOPHONIE
      1120 => 3, # STOMATOLOGIE
      1121 => 3, # OSTEO
      1122 => 3, # ACUPUNCTURE

      # Nouvelles catégories
      408 => 6, # "Conseil aux parents" (s'occuper de soi)
      702 => 2, # "Hébergement d'urgence" (se loger)
      709 => 5, # "Point d'information" (s'orienter)
      710 => 2, # "Hébergement citoyen" (se loger)
      805 => 6, # "Animations et loisirs" (s'occuper de soi)
      1200 => 7, # "Transport & mobilité" (se réinsérer)
      1201 => 7, # "Co-voiturage" (se réinsérer)
      1202 => 7, # "Mise à disposition de véhicule" (se réinsérer)
      1203 => 7, # "Transport avec chauffeur" (se réinsérer)
      1204 => 7, # Aide à la mobilité (se réinsérer)
    }

    CATEGORIES_EQUIVALENTS_REVERSED = {
      1 => [600],
      2 => [401, 700],
      3 => [100, 1100],
      4 => [300],
      5 => [400, 500, 700],
      6 => [300, 702, 704, 800, 900],
      7 => [200, 703, 705],
      40 => [304],
      41 => [605],
      42 => [301],
      43 => [302],
      61 => [903],
      63 => [901],
    }

    ISO_LANGS = {
      ab: "Abkhaz",
      aa: "Afar (Erythtrée / Ethiopie)",
      af: "Afrikaans",
      ak: "Akan (Ghana Cote ivoire)",
      sq: "Albanais",
      am: "Amharique",
      ar: "Arabe",
      brk: "Kabyle",
      brc: "Berbere Chleuh",
      an: "Aragonais",
      hy: "Arménien",
      ay: "Aymara",
      az: "Azerbaïdjanais",
      bm: "Bambara",
      ba: "Bachkir",
      be: "Biélorusse",
      bn: "Bengali (Bangladesh)",
      bh: "Bihari",
      bi: "Bislama",
      bs: "Bosniaque",
      bg: "Bulgare",
      my: "Birman",
      ca: "Catalan; Valencien",
      ce: "Tchétchène",
      ny: "Chichewa; Chewa; Nyanja",
      zh: "Chinois",
      cv: "Tchouvache",
      kw: "Cornouaillais",
      co: "Corse",
      hr: "Croate",
      cs: "Tchèque",
      da: "Danois",
      dar: "Dari, persan Afghan",
      dv: "Divehi; Dhivehi; Maldivien;",
      nl: "Néerlandais",
      en: "Anglais (English)",
      eo: "Esperanto",
      et: "Estonien",
      ee: "Ewe",
      fo: "Féroïen",
      fi: "Finlandais",
      fr: "Français",
      ff: "Fula; Fulah; Pulaar; Pular",
      gl: "Galicien",
      ka: "Georgien",
      de: "Allemand",
      el: "Grec moderne",
      gn: "Guaraní",
      gu: "Gujarati",
      ht: "Haitien; Creole",
      he: "Hebreux (Moderne)",
      hi: "Hindi",
      ho: "Hiri Motu",
      hu: "Hongrois",
      id: "Indonésien",
      ga: "Irlandais",
      ig: "Igbo (Nigéria)",
      is: "Islandais",
      it: "Italien",
      ja: "Japonais",
      ks: "Kashmiri",
      kk: "Kazakh",
      km: "Khmer",
      ki: "Kikuyu, Gikuyu",
      rw: "Kinyarwanda",
      ky: "Kirghiz, Kirghizistan",
      kg: "Kongo",
      ko: "Coréen",
      ku: "Kurde",
      kj: "Kwanyama, Kuanyama",
      lb: "Luxembourgeois, Letzeburgesch",
      lg: "Luganda",
      li: "Limbourgeois, Limbourg, Limbourg",
      ln: "Lingala",
      lo: "Lao",
      lt: "Lituanien",
      lu: "Luba-Katanga",
      lv: "Letton",
      mk: "Macedonien",
      mg: "Malagache",
      ms: "Malais",
      ml: "Malayalam",
      mt: "Maltais",
      mr: "Marathi (Marāṭhī)",
      mh: "Marshallese",
      mn: "Mongol",
      na: "Nauru",
      nv: "Navajo, Navaho",
      nd: "Ndébélés Nord",
      ne: "Nepalais",
      ng: "Ndonga",
      ii: "Nuosu",
      nr: "Ndébélés Sud",
      oc: "Occitan",
      om: "Oromo",
      os: "Ossète, Ossétique",
      pe: "Peul",
      pa: "Panjabi, Punjabi",
      pac: "Pachto",
      fa: "Persan, Farsi Iranien",
      pl: "Polonais",
      ps: "Pashto, Pushto",
      pt: "Portugais",
      qu: "Quechua (Pérou)",
      rm: "Romanche",
      rn: "Kirundi (Burundi)",
      ro: "Roumain, Moldave",
      ru: "Russe",
      sa: "Sanskrit (Saṁskṛta)",
      sd: "Sindhi",
      sm: "Samoan",
      sg: "Sango (Centreafrique)",
      sr: "Serbe",
      sn: "Shona (Zimbabwe)",
      si: "Cinghalais (Sri-lanka)",
      sk: "Slovaque",
      sl: "Slovène",
      so: "Somali",
      son: "Soninke",
      st: "Sotho du Sud",
      es: "Espanol",
      sw: "Swahili",
      ss: "Swati",
      sv: "Suédois",
      ta: "Tamil",
      te: "Telugu",
      tg: "Tajik",
      th: "Thaïlandais",
      bo: "Tibétain Standard, Tibétain, Central",
      tk: "Turkmène",
      tl: "Tagalog / Philipain",
      tr: "Turc",
      ts: "Tsonga",
      tt: "Tatar",
      tw: "Twi",
      ty: "Tahitien",
      ug: "Ouïgour, ouïghour",
      uk: "Ukrainien",
      ur: "Urdu",
      uz: "Ouzbek",
      vi: "Vietnamien",
      wo: "Wolof",
      yi: "Yiddish",
    }
  end
end
