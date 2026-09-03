module EntourageServices
  class History
    attr_accessor :entourage

    def initialize entourage
      @entourage = entourage
    end

    def get
      elements.compact.sort_by { |element| element[:date] }
    end

    protected

    def elements
      [history_from_creation] +
        history_from_moderation +
        history_from_sensitive_words_check +
        history_from_admin_notes
    end

    def history_from_creation
      {
        kind: :creation,
        date: entourage.created_at,
        moderator: nil,
        metadata: "Créé par #{entourage.user&.full_name || 'un utilisateur supprimé'}",
      }
    end

    def history_from_moderation
      moderation = entourage.moderation
      return [] unless moderation

      events = []

      if moderation.moderated_at.present?
        events << {
          kind: :moderated,
          date: moderation.moderated_at,
          moderator: moderation.moderator,
          metadata: 'Modéré',
        }
      end

      if moderation.validated_at.present?
        events << {
          kind: :validated,
          date: moderation.validated_at,
          moderator: moderation.moderator,
          metadata: 'Validé',
        }
      end

      if moderation.action_outcome_reported_at.present?
        events << {
          kind: :outcome_reported,
          date: moderation.action_outcome_reported_at,
          moderator: moderation.moderator,
          metadata: "Aboutissement renseigné : #{moderation.action_outcome}",
        }
      end

      events
    end

    def history_from_sensitive_words_check
      check = entourage.sensitive_words_check
      return [] unless check

      [{
        kind: :sensitive_words_check,
        date: check.updated_at,
        moderator: check.checked_by,
        metadata: "Mots sensibles : #{check.status}",
      }]
    end

    def history_from_admin_notes
      entourage.admin_notes.map do |note|
        {
          kind: :admin_note,
          date: note.created_at,
          moderator: note.author,
          metadata: note.body,
        }
      end
    end
  end
end
