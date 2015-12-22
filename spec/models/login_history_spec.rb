require 'rails_helper'

RSpec.describe LoginHistory, :type => :model do

  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:connected_at) }

  describe "unique by hour" do
    let!(:previous_login) { LoginHistory.create!(user_id: 1, connected_at: DateTime.parse("10/10/2010 21:15:00")) }
    it { expect(LoginHistory.new(user_id: 1, connected_at: DateTime.parse("10/10/2010 21:45:00").utc).save).to be false }
    it { expect(LoginHistory.new(user_id: 2, connected_at: DateTime.parse("10/10/2010 21:45:00").utc).save).to be true }
    it { expect(LoginHistory.new(user_id: 1, connected_at: DateTime.parse("10/10/2010 21:01:00").utc).save).to be false }

    context "fail on sempahore ? (db index problem, currently investigating)", :skip_sempahore => true do
      it { expect(LoginHistory.new(user_id: 1, connected_at: DateTime.parse("10/10/2010 20:44:00")).save).to be true }
      it { expect(LoginHistory.new(user_id: 1, connected_at: DateTime.parse("09/10/2010 21:44:00")).save).to be true }
    end

  end
end