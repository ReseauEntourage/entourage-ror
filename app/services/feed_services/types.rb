module FeedServices
  class Types
    TYPES = {
      'entourage' => {
        'as' => 'ask_for_help_social',
        'ae' => 'ask_for_help_event',
        'am' => 'ask_for_help_mat_help',
        'ar' => 'ask_for_help_resource',
        'ai' => 'ask_for_help_info',
        'ak' => 'ask_for_help_skill',
        'ao' => 'ask_for_help_other',

        'cs' => 'contribution_social',
        'ce' => 'contribution_event',
        'cm' => 'contribution_mat_help',
        'cr' => 'contribution_resource',
        'ci' => 'contribution_info',
        'ck' => 'contribution_skill',
        'co' => 'contribution_other',

        # fix wrong keys in iOS 4.1 - 4.3
        'ah' => 'ask_for_help_mat_help',
        'ch' => 'contribution_mat_help',

        'ou' => 'outing',
      },
      'entourage_pro' => {
        'tm' => 'tour_medical',
        'tb' => 'tour_barehands',
        'ta' => 'tour_alimentary',

        # fix wrong key in iOS 4.1 - 4.3
        'ts' => 'tour_barehands',
      }
    }

    def self.formated_for_user types:, user:
      return if types.nil?

      allowed_types = TYPES[user.community.slug]
      allowed_types.merge!(TYPES['entourage_pro']) if user.pro?

      types = (types || "").split(',').map(&:strip)
      types = types.map { |t| allowed_types[t] || t }

      types += ['ask_for_help_event', 'contribution_event'] if types.include?('outing')

      (types & allowed_types.values).uniq
    end

    def self.reformat_legacy_types(entourage_types, show_tours, tour_types)
      if entourage_types.nil?
        entourage_types = Entourage::ENTOURAGE_TYPES
      else
        entourage_types = entourage_types.gsub(' ', '').split(',') & Entourage::ENTOURAGE_TYPES
      end

      entourage_types = entourage_types.flat_map do |entourage_type|
        prefix = "#{entourage_type}_"
        FeedServices::Types::TYPES['entourage'].values.find_all { |type| type.starts_with?(prefix) }
      end

      return entourage_types.join(",").presence
    end
  end
end
