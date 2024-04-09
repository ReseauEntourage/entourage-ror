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

      source_categories = poi['services_all'].map { |service| service['category'] }
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
        source_category: source_categories.compact.first,
        source_categories: source_categories.compact.uniq,
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
        service['category']
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

      accueil = "#{I18n.t('pois.soliguide.public.reception', locale: lang)} #{format_accueil publics['accueil'], lang}"

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

      ["#{I18n.t('pois.soliguide.modalities.other_details')} : #{modalities['other']}"]
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
          'monday'    => I18n.t("date.abbr_day_names", locale: lang)[1],
          'tuesday'   => I18n.t("date.abbr_day_names", locale: lang)[2],
          'wednesday' => I18n.t("date.abbr_day_names", locale: lang)[3],
          'thursday'  => I18n.t("date.abbr_day_names", locale: lang)[4],
          'friday'    => I18n.t("date.abbr_day_names", locale: lang)[5],
          'saturday'  => I18n.t("date.abbr_day_names", locale: lang)[6],
          'sunday'    => I18n.t("date.abbr_day_names", locale: lang)[0],
        }[day]

        if hours['timeslot'].blank?
          hours = I18n.t('pois.soliguide.hours.closed', locale: lang)
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
      bounds.join(" #{I18n.t('pois.soliguide.hours.at')} ")
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
      "health" => 3, # SANTE
      "addiction" => 3, # ADDICTION
      "std_testing" => 3, # DEPISTAGE
      "psychological_support" => 3, # PSYCHOLOGIE
      "child_care" => 3, # SOINS_ENFANTS
      "general_practitioner" => 3, # GENERALISTE
      "dental_care" => 3, # DENTAIRE
      "pregnancy_care" => 3, # SUIVI_GROSSESSE
      "vaccination" => 3, # VACCINATION
      "infirmary" => 3, # INFIRMERIE
      "vet_care" => 3, # VETERINAIRE

      # Formation et emploi (toutes)  Se réinsérer
      "training_and_jobs" => 7, # FORMATION_EMPLOI
      "digital_tools_training" => 7, # FORMATION_NUMERIQUE
      "french_course" => 7, # FORMATION_FRANCAIS
      "job_coaching" => 7, # ACCOMPAGNEMENT_EMPLOI
      "integration_through_economic_activity" => 7, # INSERTION_ACTIVITE_ECONOMIQUE
      "tutoring" => 7, # SOUTIEN_SCOLAIRE

      # Hygiène et bien-être  Hygiène et bien-être  S'occuper de soi
      "hygiene_and_wellness" => 6, # HYGIENE
      "shower" => 42, # DOUCHE
      "laundry" => 43, # LAVERIE
      "wellness" => 6, # BIEN_ETRE
      "toilets" => 40, # TOILETTES
      "hygiene_products" => 6, # PROTECTIONS_PERIODIQUES
      "face_masks" => 3, # MASQUES

      # Conseil -> S'orienter
      "counseling" => 5, # CONSEIL
      "legal_advice" => 5, # PERMANENCE_JURIDIQUE
      "domiciliation" => 5, # DOMICILIATION
      "social_accompaniment" => 5, # ACCOMPAGNEMENT_SOCIAL
      "public_writer" => 5, # ECRIVAIN_PUBLIC
      "disability_advice" => 5, # CONSEIL_HANDICAP
      "administrative_assistance" => 5, # CONSEIL_ADMINISTRATIF
      "parent_assistance" => 5, # CONSEIL_PARENTS
      "budget_advice" => 5, # CONSEIL_BUGDET

      # Technologie (toutes)  S'orienter
      "technology" => 5, # TECHNOLOGIE
      "computers_at_your_disposal" => 5, # ORDINATEUR
      "wifi" => 5, # WIFI
      "electrical_outlets_available" => 5, # PRISE
      "telephone_at_your_disposal" => 5, # TELEPHONE
      "digital_safe" => 5, # COFFRE_FORT_NUMERIQUE

      # Alimentation (toutes sauf Fontaine)  Se nourrir
      "food" => 1, # ALIMENTATION
      "food_distribution" => 1, # DISTRIBUTION_ALIMENTAIRE
      "seated_catering" => 1, # RESTAURATION_ASSISE
      "food_packages" => 1, # COLIS_ALIMENTAIRE
      "social_grocery_stores" => 1, # EPICERIE_SOCIALE
      "fountain" => 41, # FONTAINE
      "baby_parcel" => 1, # COLIS_BEBE
      "food_voucher" => 1, # CHEQUE_ALIMENTAIRE
      "shared_kitchen" => 1, # CUISINE_PARTAGEE
      "cooking_workshop" => 1, # ATELIER_CUISINE
      "community_garden" => 1, # JARDIN_SOLIDAIRE
      "solidarity_fridge" => 1, # FRIGO_SOLIDAIRE

      # Accueil Accueil S'orienter
      "welcome" => 5, # ACCUEIL
      "day_hosting" => 5, # ACCUEIL_JOUR
      "rest_area" => 6,
      "babysitting" => 7,
      "family_area" => 6,
      "information_point" => 7,

      # Activités (Toutes)  S'occuper de soi
      "activities" => 6, # ACTIVITES
      "sport_activities" => 6, # ACTIVITES_SPORTIVES
      "museums" => 6, # MUSEE
      "libraries" => 6, # BIBLIOTHEQUE
      "other_activities" => 6, # ACTIVITES_DIVERSES
      805 => 6, # ANIMATIONS_LOISIRS

      # Matériel -> S'occuper de soi
      "equipment" => 6, # MATERIEL
      "luggage_storage" => 63, # BAGAGERIE
      "solidarity_store" => 6, # BOUTIQUE_SOLIDAIRE
      "clothing" => 61, # VETEMENTS
      "animal_assitance" => 6, # ANIMAUX

      # Spécialistes  (Toutes)  Se soigner
      "health_specialists" => 3, # SPECIALISTES
      "allergology" => 3, # ALLERGOLOGIE
      "cardiology" => 3, # CARDIOLOGIE
      "dermatology" => 3, # DERMATOLOGIE
      "echography" => 3, # ECHOGRAPHIE
      "endocrinology" => 3, # ENDOCRINOLOGIE
      "gastroenterology" => 3, # GASTRO_ENTEROLOGIE
      "gynecology" => 3, # GYNECOLOGIE
      "kinesitherapy" => 3, # KINESITHERAPIE
      "mammography" => 3, # MAMMOGRAPHIE
      "ophthalmology" => 3, # OPHTALMOLOGIE
      "otorhinolaryngology" => 3, # OTO_RHINO_LARYNGOLOGIE
      "nutrition" => 3, # NUTRITION
      "pedicure" => 3, # PEDICURE
      "phlebology" => 3, # PHLEBOLOGIE
      "pneumology" => 3, # PNEUMOLOGIE
      "radiology" => 3, # RADIOLOGIE
      "rheumatology" => 3, # RHUMATOLOGIE
      "urology" => 3, # UROLOGIE
      "speech_therapy" => 3, # ORTHOPHONIE
      "stomatology" => 3, # STOMATOLOGIE
      "osteopathy" => 3, # OSTEO
      "acupuncture" => 3, # ACUPUNCTURE

      # Mobilité
      "mobility" => 7, # "Transport & mobilité" (se réinsérer)
      "carpooling" => 7, # "Co-voiturage" (se réinsérer)
      "provision_of_vehicles" => 7, # "Mise à disposition de véhicule" (se réinsérer)
      "chauffeur_driven_transport" => 7, # "Transport avec chauffeur" (se réinsérer)
      "mobility_assistance" => 7, # Aide à la mobilité (se réinsérer)

      # Hébergement
      "accomodation_and_housing" => 2, # HEBERGEMENT_LOGEMENT
      "overnight_stop" => 2, # HALTE_NUIT
      "emergency_accommodation" => 2, # HEBERGERMENT_URGENCE
      "long_term_accomodation" => 2, # HEBERGEMENT_LONG_TERME
      "citizen_housing" => 2, # HEBERGEMENT_CITOYEN
      "access_to_housing" => 2, # CONSEIL_LOGEMENT
    }

    CATEGORIES_EQUIVALENTS_REVERSED = {
      1 => ["food"],
      2 => ["legal_advice", "welcome"],
      3 => ["health", "health_specialists"],
      4 => ["hygiene_and_wellness"],
      5 => ["counseling", "technology", "welcome"],
      6 => ["hygiene_and_wellness", "rest_area", "family_area", "activities", "equipment"],
      7 => ["training_and_jobs", "babysitting", "information_point"],
      40 => ["toilets"],
      41 => ["fountain"],
      42 => ["shower"],
      43 => ["laundry"],
      61 => ["clothing"],
      63 => ["luggage_storage"],
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
