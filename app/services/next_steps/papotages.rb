module NextSteps
  # A papotage is an online event whose title says papotage or whose category
  # is papotages (design.md, Risks: spike S4). Outing.papotages only looks at
  # the title and misses none today, but 55 of the 67 papotages of the last 12
  # months have another category, and a renamed one would only be found by its
  # category.
  module Papotages
    SF_CATEGORY = 'papotages'.freeze

    # @param scope [ActiveRecord::Relation<Outing>] narrowed by the caller (dates, status)
    # @return [Array<Integer>]
    def self.ids scope
      online = scope.unscope(:order).where(online: true)
      tagged = ActsAsTaggableOn::Tagging
        .joins(:tag)
        .where(context: 'sf_categories', taggable_type: 'Entourage', tags: { name: SF_CATEGORY })
        .select(:taggable_id)

      (online.where('entourages.title ILIKE ?', '%papotage%').pluck(:id) + online.where(id: tagged).pluck(:id)).uniq
    end
  end
end
