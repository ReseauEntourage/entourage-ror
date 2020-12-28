require 'rails_helper'

RSpec.describe AtdUser, type: :model do
  it { expect(FactoryBot.build(:atd_user).save).to be true }
  it { should belong_to :user }
  it { should validate_presence_of :atd_id }

  describe "unique atd_id" do
    let!(:atd_user) { FactoryBot.create(:atd_user, atd_id: 1) }
    it { expect(FactoryBot.build(:atd_user, atd_id: 1).save).to be false }
  end
end
