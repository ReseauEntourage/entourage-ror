class UserSmalltalkMatch
  include ActiveModel::Serialization
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :id, :smalltalk_id, :user, :users,
                :has_matched_format, :has_matched_gender,
                :has_matched_locality, :has_matched_interest,
                :has_matched_profile, :unmatch_count

  def user_smalltalk
    UserSmalltalk.find(id)
  end
  def smalltalk
    Smalltalk.find_by(id: smalltalk_id)
  end
end
