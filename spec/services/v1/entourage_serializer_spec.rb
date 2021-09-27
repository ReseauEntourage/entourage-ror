require 'rails_helper'

describe V1::EntourageSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'author' do
    let(:partner) { FactoryBot.create(:partner) }
    let(:creator) { FactoryBot.create(:public_user, partner: partner) }
    let(:entourage) { FactoryBot.create(:entourage, user: creator) }

    it 'has default keys' do
      serialization = V1::EntourageSerializer.new(entourage, scope: {
        user: FactoryBot.create(:public_user)
      })

      expect(serialization.author).to have_key(:id)
      expect(serialization.author).to have_key(:display_name)
      expect(serialization.author).to have_key(:avatar_url)
      expect(serialization.author).to have_key(:partner)
      expect(serialization.author).to have_key(:partner_role_title)
      expect(serialization.author).to have_key(:partner_with_current_user)
    end

    it 'user with no partner' do
      serialization = V1::EntourageSerializer.new(entourage, scope: {
        user: FactoryBot.create(:public_user)
      })

      expect(serialization.author).to have_key(:partner_with_current_user)
      expect(serialization.author[:partner_with_current_user]).to be(false)
    end

    it 'user with partner' do
      serialization = V1::EntourageSerializer.new(entourage, scope: {
        user: FactoryBot.create(:public_user, partner: partner)
      })

      expect(serialization.author).to have_key(:partner_with_current_user)
      expect(serialization.author[:partner_with_current_user]).to be(true)
    end
  end
end
