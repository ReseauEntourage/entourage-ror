class AlmostMatch
  include ActiveModel::Serialization
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :user_smalltalk, :smalltalk_id, :users,
                :has_matched_format, :has_matched_gender,
                :has_matched_locality, :has_matched_interest,
                :has_matched_profile, :unmatch_count
end
