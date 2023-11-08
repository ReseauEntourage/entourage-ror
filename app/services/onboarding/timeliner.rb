# send push notif to user having registered recently
module Onboarding
  class Timeliner

    I18nStruct = Struct.new(:i18n) do
      def initialize(i18n: nil)
        @i18ns = Hash.new # memorizes translations
        @i18n = i18n
      end

      def to lang
        return @i18ns[lang] if @i18ns.has_key?(lang)

        @i18ns[lang] = I18n.with_locale(lang) { I18n.t(@i18n) }
        @i18ns[lang]
      end
    end

    attr_reader :user, :method, :moderator_id

    def initialize user_id, verb
      @user = User.find(user_id)
      @method = "#{user_profile}_on_#{verb.to_s}".to_sym
    end

    def run
      return if @user.deleted?
      return unless respond_to?(@method)

      return if user_profile == :ask_for_help

      send(@method)
    rescue => e
      Rails.logger.error "PushNotificationTrigger: #{e.message}"
    end

    # h1
    def offer_help_on_h1_after_registration
      notify(
        instance: :resources,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.h1.title'),
          content: I18nStruct.new(i18n: 'timeliner.h1.offer'),
          extra: { stage: :h1 }
        }
      )
    end

    def ask_for_help_on_h1_after_registration
      notify(
        instance: :resources,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.h1.title'),
          content: I18nStruct.new(i18n: 'timeliner.h1.ask'),
          extra: { stage: :h1 }
        }
      )
    end

    # j2
    def offer_help_on_j2_after_registration
      notify(
        instance: @user.default_neighborhood,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j2.title'),
          content: I18nStruct.new(i18n: 'timeliner.j2.offer'),
          extra: { stage: :j2 }
        }
      )
    end

    def ask_for_help_on_j2_after_registration
      notify(
        instance: @user.default_neighborhood,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j2.ask_title_outing'),
          content: I18nStruct.new(i18n: 'timeliner.j2.ask'),
          extra: { stage: :j2 }
        }
      )
    end

    # j5
    def offer_help_on_j5_after_registration
      return offer_help_on_j5_after_registration_outings if user_has_outings?
      return offer_help_on_j5_after_registration_actions if user_has_actions?

      offer_help_on_j5_after_registration_create_action
    end

    def ask_for_help_on_j5_after_registration
      notify(
        instance: @user.default_neighborhood,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j5.ask_title'),
          content: I18nStruct.new(i18n: 'timeliner.j5.ask'),
          extra: { stage: :j5 }
        }
      )
    end

    def offer_help_on_j5_after_registration_outings
      notify(
        instance: :outings,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j5.title_outing'),
          content: I18nStruct.new(i18n: 'timeliner.j5.offer_outing'),
          extra: { stage: :j5 }
        }
      )
    end

    def offer_help_on_j5_after_registration_actions
      notify(
        instance: :solicitations,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j5.title_action'),
          content: I18nStruct.new(i18n: 'timeliner.j5.offer_action'),
          extra: { stage: :j5 }
        }
      )
    end

    def offer_help_on_j5_after_registration_create_action
      notify(
        instance: :contribution,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j5.title_create_action'),
          content: I18nStruct.new(i18n: 'timeliner.j5.offer_create_action'),
          extra: { stage: :j5 }
        }
      )
    end

    # j8
    def offer_help_on_j8_after_registration
      notify(
        instance: nil,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j8.title'),
          content: I18nStruct.new(i18n: 'timeliner.j8.offer'),
          extra: { stage: :j8 }
        }
      )
    end

    def ask_for_help_on_j8_after_registration
      return ask_for_help_on_j8_after_registration_outings if user_has_outings?
      return ask_for_help_on_j8_after_registration_actions if user_has_actions?

      ask_for_help_on_j8_after_registration_create_action
    end

    def ask_for_help_on_j8_after_registration_outings
      notify(
        instance: :outings,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j8.ask_title_outing'),
          content: I18nStruct.new(i18n: 'timeliner.j8.ask_outing'),
          extra: { stage: :j8 }
        }
      )
    end

    def ask_for_help_on_j8_after_registration_actions
      notify(
        instance: :solicitations,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j8.ask_title_action'),
          content: I18nStruct.new(i18n: 'timeliner.j8.ask_action'),
          extra: { stage: :j8 }
        }
      )
    end

    def ask_for_help_on_j8_after_registration_create_action
      notify(
        instance: :solicitation,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j8.ask_title_create_action'),
          content: I18nStruct.new(i18n: 'timeliner.j8.ask_create_action'),
          extra: { stage: :j8 }
        }
      )
    end

    # j11
    def offer_help_on_j11_after_registration
      notify(
        instance: nil,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j11.title'),
          content: I18nStruct.new(i18n: 'timeliner.j11.offer'),
          extra: { stage: :j11 }
        }
      )
    end

    def ask_for_help_on_j11_after_registration
      notify(
        instance: nil,
        params: {
          object: I18nStruct.new(i18n: 'timeliner.j11.title'),
          content: I18nStruct.new(i18n: 'timeliner.j11.ask'),
          extra: { stage: :j11 }
        }
      )
    end

    def notify instance:, params: {}
      notify_push(instance: instance, params: params)
      notify_inapp(instance: instance, params: params)
    end

    def notify_push instance:, params: {}
      instance = PushNotificationLinker.get(instance)

      PushNotificationService.new.send_notification(
        nil,
        params[:object],
        params[:content],
        [@user],
        instance[:instance],
        instance[:instance_id],
        instance.merge(params[:extra] || {})
      )
    end

    def notify_inapp instance:, params: {}
      instance = PushNotificationLinker.get(instance)

      InappNotificationServices::Builder.new(@user).instanciate(
        context: params[:extra][:stage],
        sender_id: nil,
        instance: instance[:instance],
        instance_id: instance[:instance_id],
        post_id: nil,
        referent: instance[:instance],
        referent_id: instance[:instance_id],
        title: params[:object].to(@user.lang),
        content: params[:content].to(@user.lang)
      )
    end

    private

    def user_has_outings?
      OutingsServices::Finder.new(@user, Hash.new).find_all.where(online: false).any?
    end

    def user_has_actions?
      user_has_solicitations? # is_ask_for_help profiles are excluded from welcome notifications
    end

    def user_has_solicitations?
      SolicitationServices::Finder.new(@user, Hash.new).find_all.any?
    end

    def user_profile
      if @user.is_ask_for_help?
        :ask_for_help
      else
        :offer_help
      end
    end
  end
end
