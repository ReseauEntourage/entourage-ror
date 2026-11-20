module NextSteps
  # The lifecycle of a user's hero (design.md, decisions 3, 9 and 10):
  # - off when NEXT_STEPS_ENABLED is "false", and during the welcome journey;
  # - the active hero is returned while valid: neither expired, nor gone, nor
  #   realised; otherwise a new one is chosen in the same call;
  # - first served = first displayed: expires at the start of D+7 (Paris
  #   time), or at the start of the event when that comes first;
  # - a concurrent call that loses the race reads the winner's hero.
  class Current
    VALIDITY_DAYS = 7
    TIME_ZONE = 'Europe/Paris'.freeze

    # kinds realised by a tap, since they leave no trace in the domain data
    TAP_REALISED_KINDS = %w[poi become_ambassador].freeze

    # What #call would return now (see #preview):
    # - state: disabled, welcome_journey, active (the valid hero), to_create (the
    #   hero the call would create, unsaved), none (nothing to suggest);
    # - previous: the active hero the call would end first, with the status it
    #   would get (expired, closed or realised).
    Preview = Struct.new(:state, :next_step, :previous, :previous_status, keyword_init: true)

    def self.enabled?
      ENV.fetch('NEXT_STEPS_ENABLED', 'true').to_s.downcase != 'false'
    end

    attr_reader :user, :now

    def initialize user, now: Time.zone.now
      @user = user
      @now = now
    end

    # @return [NextStep, nil]
    def call
      return unless self.class.enabled?
      return unless Onboarding::Journey.new(user, now: now).removed?

      active = NextStep.active.find_by(user_id: user.id)
      return active if active && still_valid!(active)

      choose(previous_kind: previous_kind(active))
    end

    # The hero #call would return now, without writing anything: neither the
    # new hero nor the end of the previous one is saved. For the back-office,
    # to test the engine without starting the 7 days of a hero the user has
    # not seen.
    # @return [Preview]
    def preview
      return Preview.new(state: 'disabled') unless self.class.enabled?
      return Preview.new(state: 'welcome_journey') unless Onboarding::Journey.new(user, now: now).removed?

      active = NextStep.active.find_by(user_id: user.id)
      previous_status = active && ending_status(active)
      return Preview.new(state: 'active', next_step: active) if active && previous_status.nil?

      selector = Selector.new(user, now: now)
      choice = hero_choice(selector, previous_kind(active))

      Preview.new(
        state: choice ? 'to_create' : 'none',
        next_step: choice ? NextStep.new(attributes(selector, choice)) : nil,
        previous: active,
        previous_status: previous_status
      )
    end

    # @return [NextStep, nil] the new hero
    def ignore! next_step
      next_step.ignore!(at: now) if next_step.active?

      call
    end

    # @return [Array<Selector::Choice>]
    def others
      return [] unless self.class.enabled?

      Selector.new(user, now: now).others
    end

    # @return [NextStepInteraction]
    def record_interaction! placement:, kind:, next_step: nil, item_kind: nil, target_type: nil, target_id: nil
      interaction = NextStepInteraction.create!(
        user: user,
        next_step: next_step,
        placement: placement,
        kind: kind,
        item_kind: next_step&.kind || item_kind,
        target_type: next_step&.target_type || target_type,
        target_id: next_step&.target_id || target_id
      )

      if kind == 'tapped' && next_step&.active? && TAP_REALISED_KINDS.include?(next_step.kind)
        next_step.realise!(at: now)
      end

      interaction
    end

    private

    def still_valid! next_step
      case ending_status(next_step)
      when 'expired' then next_step.expire!(at: now)
      when 'closed' then next_step.close!(at: now)
      when 'realised' then next_step.realise!(at: now)
      else return true
      end

      false
    end

    # @return [String, nil] the status an active hero must end with, nil while it is valid
    def ending_status next_step
      return 'expired' if next_step.expires_at <= now
      return 'closed' if Realisation.target_gone?(next_step, now: now)

      'realised' if Realisation.realised?(next_step)
    end

    def previous_kind active
      active&.kind || NextStep.where(user_id: user.id).order(created_at: :desc).pick(:kind)
    end

    def choose previous_kind:
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      selector = Selector.new(user, now: now)
      choice = hero_choice(selector, previous_kind)
      return unless choice

      next_step = NextStep.create!(attributes(selector, choice))
      log(next_step, started_at)
      next_step
    rescue ActiveRecord::RecordNotUnique
      NextStep.active.find_by(user_id: user.id)
    end

    # A failing selector must not break the home: report it, and fall back on
    # the papotage (design.md, decision 13).
    def hero_choice selector, previous_kind
      selector.hero(previous_kind: previous_kind)
    rescue StandardError => e
      Sentry.capture_exception(e)
      Rails.logger.error("next_step.selector_failed user_id=#{user.id} error=#{e.class}: #{e.message}")

      begin
        selector.fallback
      rescue StandardError => fallback_error
        Sentry.capture_exception(fallback_error)
        nil
      end
    end

    def attributes selector, choice
      candidate = choice.candidate

      {
        user: user,
        kind: candidate.kind,
        target_type: candidate.target_type,
        target_id: candidate.target_id,
        target_ids: candidate.target_ids || [],
        mode: choice.mode,
        need_id: choice.mode == 'need' ? selector.need&.solicitation_id : nil,
        segment: selector.segment.segment,
        sub_segment: selector.segment.sub_segment,
        segment_source: selector.segment.source,
        profile: profile,
        score: candidate.score,
        score_components: candidate.score_components || {},
        reason_codes: candidate.reason_codes || [],
        status: 'active',
        first_displayed_at: now,
        expires_at: expires_at(candidate)
      }
    end

    # An event is no longer suggested once it has started, even if the
    # validity is not over; and not kept beyond the validity if it is further away.
    def expires_at candidate
      validity_end = (now.in_time_zone(TIME_ZONE).to_date + VALIDITY_DAYS).in_time_zone(TIME_ZONE).beginning_of_day
      starts_at = candidate.target&.starts_at if candidate.kind == 'outing'

      starts_at ? [starts_at, validity_end].min : validity_end
    end

    def profile
      return 'team' if user.team?
      return 'ambassador' if user.ambassador?
      return 'association' if user.association? || user.goal_association?
      return 'ask_for_help' if user.is_ask_for_help?
      return 'offer_help' if user.is_offer_help?

      nil
    end

    def log next_step, started_at
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round

      Rails.logger.info(
        "next_step.selected user_id=#{user.id} kind=#{next_step.kind} mode=#{next_step.mode} " \
        "segment=#{next_step.segment.inspect} sub_segment=#{next_step.sub_segment.inspect} " \
        "segment_source=#{next_step.segment_source} duration_ms=#{duration_ms}"
      )
    end
  end
end
