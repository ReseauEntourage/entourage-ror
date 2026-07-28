module Preloaders
  module Interests
    def self.preload(records)
      return if records.empty?

      klass_name = records.first.class.base_class.name
      ids = records.map(&:id)

      tag_names_by_id = ActsAsTaggableOn::Tagging
        .joins(:tag)
        .select("taggings.taggable_id, tags.name as tag_name")
        .where(taggable_type: klass_name, context: 'interests', taggable_id: ids)
        .group_by(&:taggable_id)
        .transform_values { |ts| ts.map(&:tag_name) }

      records.each do |record|
        record.instance_variable_set(:@preloaded_interest_names, tag_names_by_id[record.id] || [])
      end
    end
  end
end
