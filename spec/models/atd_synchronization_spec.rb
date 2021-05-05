require 'rails_helper'

RSpec.describe AtdSynchronization, type: :model do
  it { expect(FactoryBot.build(:atd_synchronization).save).to be true }
  it { should validate_presence_of :filename }

  describe "unique filename" do
    let!(:atd_synchronization) { FactoryBot.create(:atd_synchronization, filename: "foo") }
    it { expect(FactoryBot.build(:atd_synchronization, filename: "foo").save).to be false }
  end
end
