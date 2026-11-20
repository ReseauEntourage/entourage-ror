module Assistant
  # The dedicated contact of a user (what the team calls their "référent"): the moderator that the
  # app shows as their contact, ModerationServices.moderator_for_user (as SummarySerializer#moderator).
  # It is not the volunteer referent of the zone (ModerationServices.referent_benevole_for_user).
  #
  # The contact may not exist: it is then returned as missing, without error. One file to change
  # when the product decides otherwise.
  class ReferentFinder
    def initialize user
      @user = user
    end

    # The moderator, or nil.
    def find
      ModerationServices.moderator_for_user(@user)
    end

    # What the handover needs: who, and how to warn them. The warning goes through the team alert
    # (SlackServices::AssistantAlert), which mentions the moderator of the zone of the person.
    def as_json(*)
      moderator = find
      return { referent: nil } unless moderator

      { referent: Presenters::Support.member(moderator).merge(warnedBy: 'team_alert') }
    end
  end
end
