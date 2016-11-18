require 'rails_helper'

RSpec.describe Entourage, type: :model do
  it { expect(FactoryGirl.build(:entourage).save!).to be true }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:entourage_type) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }
  it { should validate_presence_of(:number_of_people) }
  it { should validate_inclusion_of(:status).in_array(["open", "closed"]) }
  it { should validate_inclusion_of(:entourage_type).in_array(["ask_for_help", "contribution"]) }
  it { should belong_to(:user) }

  it "has many members" do
    user = FactoryGirl.create(:public_user)
    entourage = FactoryGirl.create(:entourage)
    FactoryGirl.create(:join_request, user: user, joinable: entourage)
    expect(entourage.members).to eq([user])
  end

  it "has many chat messages" do
    entourage = FactoryGirl.create(:entourage)
    chat_message = FactoryGirl.create(:chat_message, messageable: entourage)
    expect(entourage.chat_messages).to eq([chat_message])
  end

  describe 'moderate after create' do
    it 'should not ping Slack if description is acceptable' do
      entourage = FactoryGirl.create(:entourage, description: 'Coucou, je veux donner des jouets.')
      expect(entourage).not_to receive(:ping_slack)
    end

    it 'should ping Slack if description is unacceptable' do
      entourage = FactoryGirl.build(
        :entourage,
        description: 'Hello, je veux donner des jouets au 9 rue Marcel Sembat.'
      )

      stub_request(:any, "https://hooks.slack.com").to_return(body: "abc", status: 200)
      entourage.should_receive :ping_slack
      entourage.save
    end
  end
end
