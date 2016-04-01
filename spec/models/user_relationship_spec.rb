require 'rails_helper'

describe UserRelationship do
  
  describe 'validations' do
    it { should belong_to :source_user }
    it { should belong_to :target_user }
    it { should validate_presence_of :source_user_id }
    it { should validate_presence_of :target_user_id }
    it { should validate_presence_of :relation_type }
    it { should validate_inclusion_of(:relation_type).in_array([UserRelationship::TYPE_INVITE]) }
  end
end