# Smoke-test des traductions : exécute les vrais chemins de code (notifications push,
# notifications inapp, erreurs de validation, formats de date, messages auto de smalltalks,
# tasks des outings, badges, mailers) pour chaque langue supportée, et détecte les clés
# manquantes (I18n::MissingTranslationData) ou les mismatchs de placeholders (ArgumentError)
# sans effet de bord : aucun push/email n'est réellement envoyé, aucune ligne n'est
# persistée en base (le tout est encapsulé dans une transaction annulée).
#
# Usage (sur l'environnement de recette/staging) :
#   bundle exec rake i18n:smoke_test
#   VERBOSE=1 bundle exec rake i18n:smoke_test            # affiche aussi le texte généré
module I18nSmokeTest
  Entry = Struct.new(:category, :lang, :case_name, :status, :message, keyword_init: true)

  class << self
    def run
      @entries = []

      ActiveRecord::Base.transaction(requires_new: true) do
        run_category(:push) { check_push_notifications }
        run_category(:inapp) { check_inapp_notifications }
        run_category(:form_errors) { check_form_errors }
        run_category(:dates) { check_date_formats }
        run_category(:smalltalks) { check_smalltalks_messager }
        run_category(:outing_tasks) { check_outing_tasks }
        run_category(:badges) { check_badges }
        run_category(:mailers) { check_mailers }

        raise ActiveRecord::Rollback # sécurité : rien n'est jamais persisté, même en cas de bug dans un check
      end

      report
    end

    private

    def languages
      @languages ||= Translation::LANGUAGES.map(&:to_s)
    end

    def run_category(name)
      puts "\n== #{name} =="
      yield
    rescue => e
      add(name, '-', 'setup', :error, "la catégorie a levé une exception avant de pouvoir tester quoi que ce soit : #{e.class}: #{e.message}")
    end

    # ---- helpers communs -------------------------------------------------

    def add(category, lang, case_name, status, message)
      entry = Entry.new(category: category, lang: lang, case_name: case_name, status: status, message: message)
      @entries << entry
      print_entry(entry)
      entry
    end

    def print_entry(e)
      return if e.status == :ok && ENV['VERBOSE'] != '1'

      icon = { ok: 'OK   ', warning: 'WARN ', error: 'ERROR' }.fetch(e.status)
      puts "  [#{icon}] #{e.lang.to_s.ljust(3)} #{e.case_name.to_s.ljust(45)} #{e.message}"
    end

    # Exécute le bloc et catégorise l'exception : clé manquante / mismatch de placeholder /
    # autre erreur (potentiellement pas liée aux traductions, on le signale distinctement).
    def safe(category, lang, case_name)
      result = yield
      add(category, lang, case_name, :ok, truncate(result))
    rescue I18n::MissingTranslationData => e
      add(category, lang, case_name, :error, "clé de traduction manquante -- #{e.message}")
    rescue ArgumentError => e
      add(category, lang, case_name, :error, "ArgumentError (mismatch de placeholder %s/%{...} probable) -- #{e.message}")
    rescue => e
      add(category, lang, case_name, :error, "#{e.class}: #{e.message}")
    end

    def skip(category, case_name, reason)
      add(category, '-', case_name, :warning, "ignoré (#{reason}) -- pensez à vérifier ce cas manuellement si votre base de recette ne contient jamais ce type de donnée")
    end

    def truncate(value)
      str = value.is_a?(String) ? value : value.inspect
      str.length > 140 ? "#{str[0, 140]}…" : str
    end

    # Aplatit un namespace de config/locales/fr.yml et renvoie { "a.b.c" => "texte fr" }
    # pour les clés dont la valeur est une String (ignore les sous-hash de configuration).
    def leaf_keys(namespace)
      data = I18n.t(namespace, locale: :fr, default: {})
      flat = {}
      walk = lambda do |prefix, value|
        if value.is_a?(Hash)
          value.each { |k, v| walk.call(prefix.empty? ? k.to_s : "#{prefix}.#{k}", v) }
        else
          flat[prefix] = value
        end
      end
      walk.call('', data)
      flat
    end

    # Construit des arguments factices cohérents avec les placeholders détectés dans le
    # texte français de référence (nombre de %s, noms des %{...}).
    def fake_args_for(fr_text)
      return [] unless fr_text.is_a?(String)

      sprintf_count = fr_text.scan(/%s/).size
      named = fr_text.scan(/%\{(\w+)\}/).flatten

      if named.any?
        named.each_with_object({}) { |name, h| h[name.to_sym] = fake_value_for(name) }
      elsif sprintf_count > 0
        Array.new(sprintf_count) { |i| "test#{i + 1}" }
      else
        []
      end
    end

    def fake_value_for(name)
      case name.to_s
      when 'count' then 3
      when 'date' then Date.current.to_s
      else "test_#{name}"
      end
    end

    # ---- 1. Notifications push ------------------------------------------

    def check_push_notifications
      scenarios = [
        {
          label: 'ChatMessage (commentaire/post)',
          finder: -> { ChatMessage.where(message_type: 'text').order(id: :desc).first },
        },
        {
          label: 'JoinRequest accepté (nouvelle demande à valider par l\'organisateur)',
          # join_request_on_create (push_notification_trigger.rb:520-524) ignore les
          # auto-jointures et les conversations -- on cherche un candidat qui passe ces gardes,
          # dans un échantillon récent, plutôt que de prendre le tout dernier au hasard.
          finder: -> {
            JoinRequest.where(status: 'accepted').order(id: :desc).limit(50).detect do |jr|
              jr.joinable.present? &&
                !(jr.joinable.is_a?(Entourage) && jr.joinable.conversation?) &&
                jr.joinable.respond_to?(:user_id) && jr.joinable.user_id != jr.user_id
            end
          },
        },
        {
          label: 'JoinRequest (la demande du joiner vient d\'être acceptée)',
          finder: -> { JoinRequest.where(status: 'accepted').order(id: :desc).first },
          verb: :update,
          changes: { 'status' => ['pending', 'accepted'] },
        },
        {
          label: 'Entourage (action/outing) - création',
          finder: -> { Entourage.where(group_type: %w[action outing]).order(id: :desc).first },
          # entourage_on_create n'existe pas comme méthode : en prod, la notif de création
          # part de EntourageModeration#validated_at (push_notification_trigger.rb:105-114)
          # qui appelle directement async_entourage_on_create -- c'est le vrai point d'entrée.
          direct_method: :async_entourage_on_create,
        },
        {
          label: 'UserBadge',
          finder: -> { UserBadge.where(active: true).order(id: :desc).first },
        },
      ]

      scenarios.each do |scenario|
        label = scenario[:label]

        begin
          record = scenario[:finder].call
        rescue => e
          skip(:push, label, "#{e.class} lors de la recherche d'un enregistrement")
          next
        end

        unless record
          skip(:push, label, 'aucun enregistrement trouvé en base de recette')
          next
        end

        begin
          captured = capture_push_params(
            record,
            verb: scenario[:verb] || :create,
            changes: scenario[:changes] || {},
            direct_method: scenario[:direct_method]
          )
        rescue => e
          add(:push, '-', label, :error, "génération des notifications a levé #{e.class}: #{e.message}")
          next
        end

        if captured.empty?
          skip(:push, label, "aucune notification générée pour cet enregistrement précis (conditions métier non réunies : ex. pas de followers/voisins à notifier -- pas un bug de traduction)")
          next
        end

        captured.each do |params|
          %i[object content].each do |slot|
            i18n_struct = params[slot]
            next unless i18n_struct

            languages.each do |lang|
              safe(:push, lang, "#{label} / #{slot}") { i18n_struct.to(lang) }
            end
          end
        end
      end
    end

    # Sous-classe qui intercepte l'appel final `notify` (celui qui enverrait le vrai push,
    # écrirait l'InappNotification, et broadcasterait sur ActionCable) et capture juste les
    # I18nStruct construits, sans aucun effet de bord réseau/DB/queue.
    def capture_push_params(record, verb: :create, changes: {}, direct_method: nil)
      captured = []
      probe_class = Class.new(PushNotificationTrigger) do
        define_method(:notify) { |**params| captured << (params[:params] || {}) }
      end
      probe = probe_class.new(record, verb, changes)
      direct_method ? probe.send(direct_method, record) : probe.run
      captured
    end

    # ---- 2. Notifications inapp ------------------------------------------

    def check_inapp_notifications
      context_types = leaf_keys('activerecord.attributes.inapp_notification.context_types')
      if context_types.empty?
        skip(:inapp, 'context_types', "aucune clé trouvée sous activerecord.attributes.inapp_notification.context_types")
        return
      end

      context_types.each_key do |ctx|
        languages.each do |lang|
          safe(:inapp, lang, "context_types.#{ctx}") do
            I18n.with_locale(lang) do
              I18n.t("activerecord.attributes.inapp_notification.context_types.#{ctx}", default: ctx)
            end
          end
        end
      end

      # le title/content des inapp notifications réutilisent exactement les mêmes I18nStruct
      # que les push notifications (voir push_notification_trigger.rb#notify_inapp) : déjà
      # couvert par check_push_notifications ci-dessus.
    end

    # ---- 3. Erreurs de formulaire / validations ---------------------------

    def check_form_errors
      # NB: en prod, ces validations tournent sans `locale:` explicite -> toujours en fr
      # aujourd'hui (voir I18n.locale, jamais changé par requête). On force I18n.with_locale
      # ici pour vérifier que le contenu des 7 autres langues est correct s'il venait à être
      # utilisé (ex: si un jour la locale de la requête API est prise en compte).
      klasses = [User, Entourage, Outing, Neighborhood, Partner]

      klasses.each do |klass|
        languages.each do |lang|
          safe(:form_errors, lang, klass.name) do
            I18n.with_locale(lang) do
              instance = klass.new
              instance.valid?
              instance.errors.full_messages.join(' | ')
            end
          end
        end
      end
    rescue NameError => e
      skip(:form_errors, e.name.to_s, 'classe introuvable dans cette version du code')
    end

    # ---- 4. Formats de date -------------------------------------------------

    def check_date_formats
      formats = %i[default short long]
      formats.each do |format|
        languages.each do |lang|
          safe(:dates, lang, "I18n.l format=#{format}") { I18n.l(Time.zone.now, format: format, locale: lang) }
        end
      end

      # date_long/date_short/date_and_time sont volontairement absents hors fr (usage admin FR uniquement)
      %i[date_long date_short date_and_time].each do |format|
        safe(:dates, 'fr', "I18n.l format=#{format}") { I18n.l(Time.zone.now, format: format, locale: :fr) }
      end
    end

    # ---- 5. Messages automatiques de smalltalks -----------------------------

    def check_smalltalks_messager
      # NB: en prod, SmalltalkAutoChatMessageJob appelle I18n.t sans `locale:` -> toujours en
      # fr aujourd'hui. On teste ici le contenu des 7 autres langues au niveau de la clé de
      # traduction elle-même (structure + placeholders), sans passer par ChatMessage.create!
      # (qui déclencherait un vrai push via l'observer PushNotificationTriggerObserver).
      keys = leaf_keys('smalltalks.messager')
      keys.each do |key, fr_text|
        languages.each do |lang|
          safe(:smalltalks, lang, key) do
            I18n.with_locale(lang) do
              text = I18n.t("smalltalks.messager.#{key}")
              args = fake_args_for(fr_text)
              args.is_a?(Hash) ? I18n.t("smalltalks.messager.#{key}", **args) : (args.empty? ? text : text % args)
            end
          end
        end
      end
    end

    # ---- 6. Messages des outing tasks --------------------------------------

    def check_outing_tasks
      outing = Outing.order(id: :desc).first
      unless outing
        skip(:outing_tasks, 'reminder_content', 'aucun Outing trouvé en base de recette')
        return
      end

      languages.each do |lang|
        safe(:outing_tasks, lang, 'reminder_content') do
          I18n.with_locale(lang) { I18n.t('outings.tasks.reminder_content') }
        end
      end

      %w[reminder_7_days_with_participants reminder_7_days_without_participants].each do |key|
        languages.each do |lang|
          safe(:outing_tasks, lang, key) do
            I18n.with_locale(lang) do
              I18n.t("outings.tasks.#{key}",
                first_name: outing.user&.first_name || 'Test',
                title: outing.title || 'Test',
                count: 3,
                neighborhood: outing.user&.default_neighborhood&.try(:name) || 'Test',
                link: outing.share_url || 'https://example.org')
            end
          end
        end
      end

      %w[reminder_1_day_with_participants reminder_1_day_without_participants].each do |key|
        languages.each do |lang|
          safe(:outing_tasks, lang, key) do
            I18n.with_locale(lang) do
              I18n.t("outings.tasks.#{key}",
                first_name: outing.user&.first_name || 'Test',
                title: outing.title || 'Test',
                neighborhood: outing.user&.default_neighborhood&.try(:name) || 'Test')
            end
          end
        end
      end
    end

    # ---- 7. Traductions de badges ------------------------------------------

    def check_badges
      UserBadge::ALL_TAGS.each do |tag|
        languages.each do |lang|
          safe(:badges, lang, "email.badge.#{tag}") { UserBadge.display_data_for(tag, locale: lang) }
        end
      end

      badge_mailer_keys = leaf_keys('badge_mailer.badges')
      badge_mailer_keys.each do |key, fr_text|
        languages.each do |lang|
          safe(:badges, lang, "badge_mailer.badges.#{key}") do
            I18n.with_locale(lang) do
              text = I18n.t("badge_mailer.badges.#{key}", default: nil)
              next text if text.nil? # progression_label."3", "4"... n'existent pas forcément, normal

              args = fake_args_for(fr_text)
              args.is_a?(Hash) ? I18n.t("badge_mailer.badges.#{key}", **args) : (args.empty? ? text : text % args)
            end
          end
        end
      end

      safe(:badges, '-', 'badge_mailer.duration') do
        languages.map { |lang| I18n.t('badge_mailer.duration', count: 3, locale: lang) }.join(' | ')
      end
    end

    # ---- 8. Mailers ---------------------------------------------------------

    def check_mailers
      user = User.where.not(email: [nil, '']).order(id: :desc).first
      unless user
        skip(:mailers, 'all', "aucun User avec email trouvé en base de recette")
        return
      end

      languages.each do |lang|
        safe(:mailers, lang, 'MemberMailer.congratulations_new_badge') do
          with_lang(user, lang) do
            MemberMailer.congratulations_new_badge(user, 'fidele_papotages', Time.current).message
          end
        end
      end

      languages.each do |lang|
        safe(:mailers, lang, 'BadgeMailer.deactivation_warning') do
          with_lang(user, lang) do
            BadgeMailer.deactivation_warning(user, 'voix_presente', 1, 3).message
          end
        end
      end

      languages.each do |lang|
        safe(:mailers, lang, 'BadgeMailer.deactivated') do
          with_lang(user, lang) do
            BadgeMailer.deactivated(user, 'voix_presente', 30.days.ago, Time.current).message
          end
        end
      end

      outing = Outing.order(id: :desc).first
      if outing
        languages.each do |lang|
          safe(:mailers, lang, 'GroupMailer.event_created_confirmation') do
            with_lang(outing.user || user, lang) do
              GroupMailer.event_created_confirmation(outing).message
            end
          end
        end
      else
        skip(:mailers, 'GroupMailer.event_created_confirmation', 'aucun Outing trouvé en base de recette')
      end
    end

    # Change `user.lang` en mémoire uniquement (jamais persisté, aucun `save`).
    def with_lang(user, lang)
      original = user.lang
      user.lang = lang
      yield
    ensure
      user.lang = original
    end

    # ---- rapport final -------------------------------------------------------

    def report
      puts "\n#{'=' * 100}"
      puts "RÉSUMÉ"
      puts '=' * 100

      by_category = @entries.group_by(&:category)
      by_category.each do |category, entries|
        errors = entries.select { |e| e.status == :error }
        warnings = entries.select { |e| e.status == :warning }
        ok = entries.count { |e| e.status == :ok }
        puts "#{category.to_s.ljust(15)} #{ok} OK, #{warnings.size} avertissement(s), #{errors.size} erreur(s)"
      end

      total_errors = @entries.count { |e| e.status == :error }
      total_warnings = @entries.count { |e| e.status == :warning }

      if total_errors.positive?
        puts "\nDÉTAIL DES ERREURS :"
        @entries.select { |e| e.status == :error }.each do |e|
          puts "  [#{e.category}] #{e.lang} / #{e.case_name} : #{e.message}"
        end
      end

      puts "\n#{total_errors.zero? ? 'SUCCÈS' : 'ÉCHEC'} -- #{total_errors} erreur(s), #{total_warnings} avertissement(s) sur #{@entries.size} vérifications."

      exit(1) if total_errors.positive?
    end
  end
end
