module SuggestionServices
  class Generate
    ACTIVE_DAYS = 30

    class << self
      def for_user(user)
        raise ArgumentError, "user is required" unless user.present?

        connection = active_suggestion(user, 'connection') || generate_connection(user)
        next_step  = active_suggestion(user, 'next_step')  || generate_next_step(user)

        { connection: connection, next_step: next_step }
      rescue ArgumentError
        raise
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#for_user] user=#{user&.id} #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        { connection: nil, next_step: nil }
      end

      def generate_connection(user)
        postal_code = user_postal_code(user)

        unless postal_code.present?
          Rails.logger.info "[SuggestionServices::Generate#generate_connection] user=#{user.id} skipped: no primary address"
          return nil
        end

        excluded_ids = [user.id] +
                       existing_conversation_user_ids_for(user) +
                       dismissed_suggested_user_ids_for(user)

        pool = User
          .joins("INNER JOIN addresses ON addresses.user_id = users.id AND addresses.position = 1")
          .where("addresses.postal_code = ?", postal_code)
          .where.not(id: excluded_ids)
          .where("users.deleted = false")
          .where(active_users_condition)
          .select("users.id, users.goal, users.targeting_profile")
          .limit(100)

        if pool.empty?
          Rails.logger.info "[SuggestionServices::Generate#generate_connection] user=#{user.id} skipped: empty pool for postal_code=#{postal_code}"
          return nil
        end

        user_seg           = user_segment(user)
        user_interests     = user.interest_list
        user_profile       = user_targeting_profile(user)
        event_attendee_ids = event_attendee_ids_for(user)
        engagement_counts  = engagement_counts_for(pool.map(&:id))

        scored = pool.map do |candidate|
          score     = 0
          breakdown = []

          if event_attendee_ids.include?(candidate.id)
            score += 3
            breakdown << :event
          end

          candidate_profile = user_targeting_profile(candidate)
          if profile_complement?(user_profile, candidate_profile)
            score += 2
            breakdown << :profile
          end

          if user_interests.any?
            shared = (user_interests & candidate.interest_list).size
            interest_score = [shared, 3].min
            if interest_score > 0
              score += interest_score
              breakdown << :interests
            end
          end

          candidate_seg = segment_from_count(engagement_counts[candidate.id] || 0)
          if engagement_complement?(user_seg, candidate_seg)
            score += 2
            breakdown << :engagement
          end

          { id: candidate.id, score: score, breakdown: breakdown }
        end

        best = scored.max_by { |c| [c[:score], rand] }
        return nil unless best

        reason, reason_type = connection_reason(best[:breakdown], user_profile)

        Rails.logger.info "[SuggestionServices::Generate#generate_connection] user=#{user.id} candidate=#{best[:id]} score=#{best[:score]} signals=#{best[:breakdown]}"

        UserSuggestion.create!(
          user:              user,
          suggestion_type:   'connection',
          suggested_user_id: best[:id],
          reason:            reason,
          reason_type:       reason_type,
          expires_at:        7.days.from_now
        )
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "[SuggestionServices::Generate#generate_connection] user=#{user&.id} RecordInvalid: #{e.message}"
        nil
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#generate_connection] user=#{user&.id} #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        nil
      end

      def generate_next_step(user)
        segment     = user_segment(user)
        postal_code = user_postal_code(user)

        suggestion_attrs = case segment
        when :silencieux  then next_step_for_silencieux(user, postal_code)
        when :curieux     then next_step_for_curieux(user)
        when :observateur then next_step_for_observateur(user)
        when :contributeur then next_step_for_contributeur(user)
        when :pilier      then { suggested_action: 'create_event', reason: "Vous êtes un pilier de votre communauté", reason_type: 'zone' }
        end

        unless suggestion_attrs.present?
          Rails.logger.info "[SuggestionServices::Generate#generate_next_step] user=#{user.id} segment=#{segment} no content available"
          return nil
        end

        attrs          = suggestion_attrs.merge(user: user, suggestion_type: 'next_step', expires_at: 5.days.from_now)
        entourage_id   = attrs.delete(:suggested_entourage_id)
        suggested_uid  = attrs.delete(:suggested_user_id_val)

        record = UserSuggestion.new(attrs)
        record.suggested_entourage_id = entourage_id if entourage_id
        record.suggested_user_id      = suggested_uid if suggested_uid

        unless record.valid?
          Rails.logger.error "[SuggestionServices::Generate#generate_next_step] user=#{user.id} invalid: #{record.errors.full_messages.join(', ')}"
          return nil
        end

        record.save!
        Rails.logger.info "[SuggestionServices::Generate#generate_next_step] user=#{user.id} segment=#{segment} action=#{record.suggested_action}"
        record
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "[SuggestionServices::Generate#generate_next_step] user=#{user&.id} RecordInvalid: #{e.message}"
        nil
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#generate_next_step] user=#{user&.id} #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        nil
      end

      private

      def active_suggestion(user, type)
        user.user_suggestions.active.for_type(type).order(created_at: :desc).first
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#active_suggestion] user=#{user&.id} type=#{type} #{e.class}: #{e.message}"
        nil
      end

      def user_postal_code(user)
        Address.where(user_id: user.id, position: 1).pick(:postal_code)
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#user_postal_code] user=#{user&.id} #{e.class}: #{e.message}"
        nil
      end

      def active_users_condition
        <<-SQL
          (
            users.id IN (
              SELECT DISTINCT user_id FROM login_histories
              WHERE connected_at > NOW() - INTERVAL '#{ACTIVE_DAYS} days'
            )
            OR
            users.id IN (
              SELECT DISTINCT user_id FROM denorm_daily_engagements_with_type
              WHERE date > NOW() - INTERVAL '#{ACTIVE_DAYS} days'
            )
          )
        SQL
      end

      def existing_conversation_user_ids_for(user)
        JoinRequest
          .joins("INNER JOIN entourages ON entourages.id = join_requests.joinable_id")
          .where(joinable_type: 'Entourage', status: 'accepted')
          .where("entourages.group_type = 'conversation'")
          .where(
            "join_requests.joinable_id IN (?)",
            JoinRequest
              .where(joinable_type: 'Entourage', user_id: user.id, status: 'accepted')
              .joins("INNER JOIN entourages ON entourages.id = join_requests.joinable_id")
              .where("entourages.group_type = 'conversation'")
              .select(:joinable_id)
          )
          .where.not(user_id: user.id)
          .pluck(:user_id)
          .uniq
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#existing_conversation_user_ids_for] user=#{user&.id} #{e.class}: #{e.message}"
        []
      end

      def dismissed_suggested_user_ids_for(user)
        UserSuggestion
          .where(user_id: user.id, suggestion_type: 'connection')
          .where.not(suggested_user_id: nil)
          .where.not(dismissed_at: nil)
          .pluck(:suggested_user_id)
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#dismissed_suggested_user_ids_for] user=#{user&.id} #{e.class}: #{e.message}"
        []
      end

      def user_targeting_profile(user)
        tp   = user.targeting_profile.to_s
        goal = user.goal.to_s
        return :ask_for_help if tp == 'asks_for_help' || goal == 'ask_for_help'
        return :offer_help   if tp == 'offers_help'   || goal == 'offer_help'
        nil
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#user_targeting_profile] user=#{user&.id} #{e.class}: #{e.message}"
        nil
      end

      def profile_complement?(a, b)
        (a == :ask_for_help && b == :offer_help) ||
        (a == :offer_help   && b == :ask_for_help)
      end

      LOW_SEGMENTS  = %i[silencieux observateur].freeze
      HIGH_SEGMENTS = %i[contributeur pilier].freeze

      def engagement_complement?(user_seg, candidate_seg)
        LOW_SEGMENTS.include?(user_seg) && HIGH_SEGMENTS.include?(candidate_seg)
      end

      def engagement_counts_for(user_ids)
        return {} if user_ids.empty?

        rows = DenormDailyEngagementsWithType
          .where(user_id: user_ids)
          .where("date > ?", ACTIVE_DAYS.days.ago)
          .group(:user_id)
          .select("user_id, COUNT(DISTINCT engagement_type) AS eng_count")

        rows.each_with_object({}) { |r, h| h[r.user_id] = r.eng_count.to_i }
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#engagement_counts_for] #{e.class}: #{e.message}"
        {}
      end

      def segment_from_count(count)
        case count
        when 0    then :silencieux
        when 1..2 then :curieux
        when 3..4 then :observateur
        when 5..6 then :contributeur
        else           :pilier
        end
      end

      def event_attendee_ids_for(user)
        common_entourage_ids = JoinRequest
          .where(joinable_type: 'Entourage', user_id: user.id, status: 'accepted')
          .joins("INNER JOIN entourages ON entourages.id = join_requests.joinable_id")
          .where("entourages.group_type = 'outing'")
          .where("join_requests.created_at > ?", ACTIVE_DAYS.days.ago)
          .pluck(:joinable_id)

        return [] unless common_entourage_ids.any?

        JoinRequest
          .where(joinable_type: 'Entourage', joinable_id: common_entourage_ids, status: 'accepted')
          .where.not(user_id: user.id)
          .pluck(:user_id)
          .uniq
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#event_attendee_ids_for] user=#{user&.id} #{e.class}: #{e.message}"
        []
      end

      def connection_reason(breakdown, user_profile)
        if breakdown.include?(:event)
          return ["parce que vous avez participé au même événement", 'event']
        end
        if breakdown.include?(:profile)
          label = user_profile == :ask_for_help ?
            "parce qu'il est riverain et peut vous présenter le quartier" :
            "parce qu'il cherche à mieux s'intégrer dans le quartier"
          return [label, 'zone']
        end
        if breakdown.include?(:interests)
          return ["parce que vous avez des centres d'intérêt en commun", 'zone']
        end
        if breakdown.include?(:engagement)
          return ["parce qu'il est actif dans votre quartier et peut vous guider", 'zone']
        end
        ["parce que vous êtes dans le même quartier", 'zone']
      end

      def user_segment(user)
        count = DenormDailyEngagementsWithType
          .where(user_id: user.id)
          .where("date > ?", ACTIVE_DAYS.days.ago)
          .distinct
          .count(:engagement_type)

        segment_from_count(count)
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#user_segment] user=#{user&.id} #{e.class}: #{e.message}"
        :silencieux
      end

      def next_step_for_silencieux(user, postal_code)
        unless postal_code.present?
          Rails.logger.info "[SuggestionServices::Generate#next_step_for_silencieux] user=#{user.id} skipped: no postal_code"
          return nil
        end

        outing = Entourage
          .where(group_type: 'outing', status: 'open')
          .where(postal_code: postal_code)
          .where("(metadata->>'starts_at')::timestamp > ?", Time.current)
          .where("(metadata->>'starts_at')::timestamp < ?", 7.days.from_now)
          .order(Arel.sql("(metadata->>'starts_at')::timestamp ASC"))
          .first

        return { suggested_entourage_id: outing.id, suggested_action: 'join_event',
                 reason: "Il y a un événement proche de chez vous", reason_type: 'zone' } if outing

        group = Entourage
          .where(group_type: 'neighborhood', status: 'open')
          .where(postal_code: postal_code)
          .order(created_at: :desc)
          .first

        return { suggested_entourage_id: group.id, suggested_action: 'join_group',
                 reason: "Il y a un groupe actif dans votre quartier", reason_type: 'zone' } if group

        candidate = User
          .joins("INNER JOIN addresses ON addresses.user_id = users.id AND addresses.position = 1")
          .where("addresses.postal_code = ?", postal_code)
          .where.not(id: user.id)
          .where("users.deleted = false")
          .where(active_users_condition)
          .order("RANDOM()")
          .limit(1)
          .first

        return nil unless candidate

        { suggested_user_id_val: candidate.id, suggested_action: 'say_hello',
          reason: "Il y a des membres actifs près de chez vous", reason_type: 'zone' }
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#next_step_for_silencieux] user=#{user&.id} #{e.class}: #{e.message}"
        nil
      end

      def next_step_for_curieux(user)
        posted_ids = ChatMessage
          .where(user_id: user.id, messageable_type: 'Entourage')
          .where("created_at > ?", ACTIVE_DAYS.days.ago)
          .pluck(:messageable_id)
          .presence || [0]

        silent_group = JoinRequest
          .joins("INNER JOIN entourages ON entourages.id = join_requests.joinable_id")
          .where(user_id: user.id, joinable_type: 'Entourage', status: 'accepted')
          .where("entourages.group_type IN ('neighborhood', 'action')")
          .where("join_requests.joinable_id NOT IN (?)", posted_ids)
          .order("RANDOM()")
          .limit(1)
          .pluck("join_requests.joinable_id")
          .first

        return { suggested_entourage_id: silent_group, suggested_action: 'write_group',
                 reason: "Vous n'avez pas encore participé à ce groupe", reason_type: 'group' } if silent_group

        postal_code = user_postal_code(user)
        return nil unless postal_code.present?

        outing = Entourage
          .where(group_type: 'outing', status: 'open')
          .where(postal_code: postal_code)
          .where("(metadata->>'starts_at')::timestamp > ?", Time.current)
          .order(Arel.sql("(metadata->>'starts_at')::timestamp ASC"))
          .first

        return nil unless outing

        { suggested_entourage_id: outing.id, suggested_action: 'join_event',
          reason: "Il y a un événement proche de chez vous", reason_type: 'zone' }
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#next_step_for_curieux] user=#{user&.id} #{e.class}: #{e.message}"
        nil
      end

      def next_step_for_observateur(user)
        { suggested_action: 'create_action',
          reason: "Vous participez régulièrement aux événements",
          reason_type: 'zone' }
      end

      def next_step_for_contributeur(user)
        new_member = JoinRequest
          .joins("INNER JOIN entourages ON entourages.id = join_requests.joinable_id")
          .joins("INNER JOIN join_requests AS my_jr ON my_jr.joinable_id = join_requests.joinable_id AND my_jr.joinable_type = 'Entourage'")
          .where("my_jr.user_id = ? AND my_jr.status = 'accepted'", user.id)
          .where(joinable_type: 'Entourage', status: 'accepted')
          .where.not("join_requests.user_id" => user.id)
          .where("join_requests.created_at > ?", 7.days.ago)
          .order("RANDOM()")
          .limit(1)
          .pluck("join_requests.user_id")
          .first

        return nil unless new_member

        { suggested_user_id_val: new_member, suggested_action: 'welcome_member',
          reason: "Un nouveau membre a rejoint votre groupe", reason_type: 'group' }
      rescue => e
        Rails.logger.error "[SuggestionServices::Generate#next_step_for_contributeur] user=#{user&.id} #{e.class}: #{e.message}"
        nil
      end
    end
  end
end
