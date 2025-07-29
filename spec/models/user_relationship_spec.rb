require 'rails_helper'

describe UserRelationship do

  describe 'validations' do
    it { should belong_to :source_user }
    it { should belong_to :target_user }
    it { should validate_presence_of :source_user_id }
    it { should validate_presence_of :target_user_id }
    it { should validate_presence_of :relation_type }
    it { should validate_inclusion_of(:relation_type).in_array([UserRelationship::TYPE_INVITE,
                                                                UserRelationship::TYPE_FACEBOOK]) }
  end


  describe 'has unique relationship' do
    let(:user1) {FactoryBot.create(:public_user)}
    let(:user2) {FactoryBot.create(:public_user)}

    context 'first relationship' do
      it 'saves the relationship' do
        ur = UserRelationship.new(source_user: user1,

                                  target_user: user2,
                                  relation_type: UserRelationship::TYPE_INVITE)
        expect(ur.save).to be true
      end
    end


    context 'user relationship already exists' do
      before { UserRelationship.create(source_user: user1,
                                    target_user: user2,
                                    relation_type: UserRelationship::TYPE_INVITE ) }

      it 'refuses same relationship' do
        ur = UserRelationship.new(source_user: user1,

                                  target_user: user2,
                                  relation_type: UserRelationship::TYPE_INVITE)
        expect(ur.save).to be false
      end

      it 'accepts relationship of different type' do
        ur = UserRelationship.new(source_user: user1,

                                  target_user: user2,
                                  relation_type: UserRelationship::TYPE_FACEBOOK)
        expect(ur.save).to be true
      end

      it 'accepts relationship with different user' do
        ur = UserRelationship.new(source_user: FactoryBot.create(:public_user),

                                  target_user: user2,
                                  relation_type: UserRelationship::TYPE_INVITE)
        expect(ur.save!).to be true
      end
    end
  end
end
