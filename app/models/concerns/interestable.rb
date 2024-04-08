module Interestable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :interests

    validate :validate_interest_list!

    scope :join_tags, -> {
      joins(sanitize_sql_array [%(
        left join taggings on taggable_type = '%s' and taggable_id = %s.id
        left join tags on tags.id = taggings.tag_id
      ), self.name, self.table_name])
    }

    scope :order_by_interests_matching, -> (interest_list) {
      return unless interest_list
      return unless interest_list.any?

      join_tags
        .group(sanitize_sql_array ["%s.id", self.table_name])
        .order(Arel.sql %(
        sum(
          case context = 'interests' and tagger_id is null and tags.name in (%s)
          when true then 1
          else 0
          end
        ) desc
      ) % interest_list.map { |interest| "'#{interest}'" }.join(","))
    }

    scope :order_with_interests, -> {
      join_tags
        .group(sanitize_sql_array ["%s.id", self.table_name])
        .order(Arel.sql %(
          sum(case when tags.id is not null then 1 else 0 end) desc
        ))
    }

    scope :match_at_least_one_interest, -> (interest_list) {
      return unless interest_list
      return unless interest_list.any?

      joins(:interests).where(interests: { name: interest_list })
    }
  end

  def validate_interest_list!
    wrongs = self.interest_list.reject do |interest|
      Tag.interest_list.include?(interest)
    end

    errors.add(:interests, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def interests= interests
    if interests.is_a? Array
      self.interest_list = interests.join(', ')
    elsif interests.is_a? String
      self.interest_list = interests
    end
  end

  def interest_names
    # optimization to resolve n+1
    interests.map(&:name)
  end
end
