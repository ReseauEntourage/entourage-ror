module PoiServices
  class SoliguideFormatter
    # @todo add unit tests
    # @todo refactor: get specific formatter for services_all, location, entity, languages
    def self.format poi, lang = nil
      lang ||= Translation::DEFAULT_LANG

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
        name: format_title(poi['name'], poi['entity']['name'], lang),
        description: format_description(poi['description'], lang),
        longitude: poi['position']['location']['coordinates'][0].round(6),
        latitude: poi['position']['location']['coordinates'][1].round(6),
        address: poi['position']['adresse'].presence,
        postal_code: poi['position']['codePostal'].presence,
        phone: format_phones(phones, lang).first,
        phones: format_phones(phones, lang).join(', '),
        website: poi['entity']['website'].presence,
        email:poi['entity']['mail'].presence,
        audience: format_audience(poi['publics'], poi['modalities'], lang),
        category_ids: format_category_ids(poi, lang),
        source_category_id: source_categories.compact.first,
        source_category_ids: source_categories.compact.uniq,
        hours: format_hours(poi['newhours'], lang),
        languages: languages.map { |l| ISO_LANGS[l.to_sym] }.compact.join(', ')
      }
    end

    def self.format_short poi, lang = nil
      lang ||= Translation::DEFAULT_LANG

      return nil unless poi

      category_ids = format_category_ids(poi, lang)

      {
        uuid: "s#{poi['lieu_id']}",
        source_id: poi['lieu_id'],
        name: format_title(poi['name'], poi['entity']['name'], lang),
        longitude: poi['position']['location']['coordinates'][0].round(6),
        latitude: poi['position']['location']['coordinates'][1].round(6),
        address: poi['position']['adresse'],
        postal_code: poi['position']['codePostal'].presence,
        phone: poi['entity']['phone'],
        category_id: category_ids.any? ? category_ids[0] : 0,
        partner_id: nil
      }
    end

    def self.format_audience publics, modalities, lang
      (format_publics(publics, lang) + format_modalities(modalities, lang) + format_other_modalities(modalities, lang)).join("\n")
    end

    def self.format_category_ids poi, lang
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
    def self.format_publics publics, lang
      return [] unless publics

      sentences = []

      accueil = "Accueil #{format_accueil publics['accueil'], lang}"

      sentences << if publics['accueil'] == 0
        accueil
      else
        "#{accueil} : #{(
          format_age(publics['age'], lang) +
          format_familialle(publics['familialle'], lang) +
          format_other(publics['other'], lang)
        ).compact.join(', ')}"
      end

      if format_administrative(publics['administrative'], lang)
        sentences << I18n.t('pois.soliguide.public.administrative', locale: lang) % format_administrative(publics['administrative'], lang)
      end

      if publics['description'].present?
        sentences << I18n.t('pois.soliguide.public.description', locale: lang) % publics['description']
      end

      sentences.compact
    end

    def self.format_accueil accueil, lang
      return I18n.t('pois.soliguide.accueil.preferentiel', locale: lang) if accueil == 1
      return I18n.t('pois.soliguide.accueil.exclusif', locale: lang) if accueil == 2

      I18n.t('pois.soliguide.accueil.inconditionnel', locale: lang)
    end

    def self.format_age age, lang
      return [] unless age

      min = age['min'].presence
      max = age['max'].presence

      return [] unless min || max

      return [I18n.t('pois.soliguide.age.mineur', locale: lang)] if max && max <= 18
      return [I18n.t('pois.soliguide.age.adulte', locale: lang)] if min == 18 && max == 99
      return [I18n.t('pois.soliguide.age.from', locale: lang) % min] if min.present? && max.nil?
      return [] if min == 0 && max == 99 # tous ages
      return [I18n.t('pois.soliguide.age.from_to', locale: lang) % [min, max]] if min.present? && max.present?

      []
    end

    def self.format_familialle familialle, lang
      # isolated : personne isolée
      # family : famille
      # couple : couple
      # pregnant : femme enceinte
      return [] unless familialle.present?
      return [] if familialle.sort == ['isolated', 'family', 'couple', 'pregnant'].sort

      # translate isolated in a given languag

      familialle.map do |term|
        case term
        when 'isolated' then I18n.t('pois.soliguide.familiale.isolated', locale: lang)
        when 'family' then I18n.t('pois.soliguide.familiale.family', locale: lang)
        when 'couple' then I18n.t('pois.soliguide.familiale.couple', locale: lang)
        when 'pregnant' then I18n.t('pois.soliguide.familiale.pregnant', locale: lang)
        end
      end
    end

    def self.format_administrative administrative, lang
      return nil unless administrative.present?
      return nil if administrative.sort == ["asylum", "refugee", "regular", "undocumented"].sort

      # regular : personne en situation régulière
      # asylum : personne demandeur⋅euse d'asile
      # refugee : personne avec le statut de réfugié
      # undocumented : personne sans papier

      situations = []
      situations << I18n.t('pois.soliguide.administrative.regular', locale: lang) if administrative.include?('regular')
      situations << I18n.t('pois.soliguide.administrative.undocumented', locale: lang) if administrative.include?('undocumented')
      situations << I18n.t('pois.soliguide.administrative.asylum', locale: lang) if administrative.include?('asylum')
      situations << I18n.t('pois.soliguide.administrative.refugee', locale: lang) if administrative.include?('refugee')

      I18n.t('pois.soliguide.administrative.default', locale: lang) % situations.join(', ')
    end

    def self.format_other other, lang
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
      others << I18n.t('pois.soliguide.other.violence', locale: lang) if other.include?('violence')
      others << I18n.t('pois.soliguide.other.addiction', locale: lang) if other.include?('addiction')
      others << I18n.t('pois.soliguide.other.handicap', locale: lang) if other.include?('handicap')
      others << I18n.t('pois.soliguide.other.lgbt', locale: lang) if other.include?('lgbt+')
      others << I18n.t('pois.soliguide.other.hiv', locale: lang) if other.include?('hiv')
      others << I18n.t('pois.soliguide.other.prostitution', locale: lang) if other.include?('prostitution')
      others << I18n.t('pois.soliguide.other.prison', locale: lang) if other.include?('prison')
      others << I18n.t('pois.soliguide.other.student', locale: lang) if other.include?('student')

      others
    end

    def self.format_modalities modalities, lang
      return [] unless modalities
      return [I18n.t('pois.soliguide.modalities.inconditionnel', locale: lang)] if modalities['inconditionnel'] == true

      sentences = []

      #  - modalities.inconditionnel qui définit si une structure n'a pas de conditions d'accès spécifiques. Si modalities.inconditionnel est à true, alors les autres données ne sont pas à prendre en compte (et sont à false de manière générale) ;
      #  - modalities.appointment.checked qui définit si une structure est sur RDV ou pas ;
      #  - modalities.inscription.checked qui définit si une structure est sur inscription ou pas ;
      #  - modalities.orientation.checked qui définit si une structure est sur orientation ou pas ;
      # Les 3 dernières données (appointment, inscription, orientation) sont cumulables (une structure peut être à la fois sur RDV et sur orientation) mais pas avec inconditionnel

      if modalities['appointment'] && modalities['appointment']['checked'] == true
        sentences << I18n.t('pois.soliguide.modalities.appointment', locale: lang) % modalities['appointment']['precisions']
      end

      if modalities['inscription'] && modalities['inscription']['checked'] == true
        sentences << I18n.t('pois.soliguide.modalities.inscription', locale: lang) % modalities['inscription']['precisions']
      end

      if modalities['orientation'] && modalities['orientation']['checked'] == true
        sentences << I18n.t('pois.soliguide.modalities.orientation', locale: lang) % modalities['orientation']['precisions']
      end

      sentences << format_animal(modalities['animal'], lang)

      sentences.compact
    end

    def self.format_animal animal, lang
      return nil unless animal.present?
      return nil if animal['checked'].nil?
      return I18n.t('pois.soliguide.animal.unauthorized', locale: lang) unless animal['checked']

      I18n.t('pois.soliguide.animal.authorized', locale: lang)
    end

    def self.format_other_modalities modalities, lang
      return [] unless modalities.present?
      return [] unless modalities['other'].present?

      ["Autres précisions : #{modalities['other']}"]
    end

    def self.format_hours hours, lang
      return [] unless hours

      available_days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
      # excluded keys are: closedHolidays, description

      hours.slice(*available_days).sort_by do |days, value|
        available_days.find_index(days) || -1
      end.map do |day, hours|
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
            format_hour_range(timeslot['start'], timeslot['end'], lang)
          end.compact.join(' - ')
        end

        "#{day} : #{hours}"
      end.compact.join("\n")
    end

    def self.format_hour_range left, right, lang
      bounds = [left, right].map { |bound| format_hour(bound, lang) }
      return if bounds.any?(&:nil?)
      bounds.join(' à ')
    end

    def self.format_hour seconds, lang
      return if seconds.nil? || seconds == -1
      hours = seconds / 100
      minutes = seconds % 100
      "%dh%02d" % [hours, minutes]
    end

    def self.format_title place_name, entity_name, lang
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

    def self.format_description string, lang
      Nokogiri::HTML(string).text
        .gsub(/\n\n+/, "\n\n") # Never leave more than 2 consecutive newlines.
        .strip                 # Strip leading and trailing whitespace.
    end

    def self.format_phones phones, lang
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
      107 => 3, # SUIVI_GROSSESSE
      108 => 3, # VACCINATION
      109 => 3, # INFIRMERIE
      110 => 3, # VETERINAIRE

      # Formation et emploi (toutes)  Se réinsérer
      200 => 7, # FORMATION_EMPLOI
      201 => 7, # FORMATION_NUMERIQUE
      202 => 7, # FORMATION_FRANCAIS
      203 => 7, # ACCOMPAGNEMENT_EMPLOI
      204 => 7, # INSERTION_ACTIVITE_ECONOMIQUE
      205 => 7, # SOUTIEN_SCOLAIRE

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
      401 => 5, # PERMANENCE_JURIDIQUE
      402 => 5, # DOMICILIATION
      403 => 5, # ACCOMPAGNEMENT_SOCIAL
      404 => 5, # ECRIVAIN_PUBLIC
      405 => 5, # CONSEIL_HANDICAP
      406 => 5, # CONSEIL_ADMINISTRATIF
      407 => 5, # CONSEIL_PARENTS
      408 => 5, # CONSEIL_BUGDET

      # Technologie (toutes)  S'orienter
      500 => 5, # TECHNOLOGIE
      501 => 5, # ORDINATEUR
      502 => 5, # WIFI
      503 => 5, # PRISE
      504 => 5, # TELEPHONE
      505 => 5, # COFFRE_FORT_NUMERIQUE

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
      805 => 6, # ANIMATIONS_LOISIRS

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
      1200 => 7, # "Transport & mobilité" (se réinsérer)
      1201 => 7, # "Co-voiturage" (se réinsérer)
      1202 => 7, # "Mise à disposition de véhicule" (se réinsérer)
      1203 => 7, # "Transport avec chauffeur" (se réinsérer)
      1204 => 7, # Aide à la mobilité (se réinsérer)

      1300 => 2, # HEBERGEMENT_LOGEMENT
      1301 => 2, # HALTE_NUIT
      1302 => 2, # HEBERGERMENT_URGENCE
      1303 => 2, # HEBERGEMENT_LONG_TERME
      1304 => 2, # HEBERGEMENT_CITOYEN
      1305 => 2, # CONSEIL_LOGEMENT
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
