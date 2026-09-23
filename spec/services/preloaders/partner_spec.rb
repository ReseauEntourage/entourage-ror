require 'rails_helper'

describe Preloaders::Partner do
  describe '.preload_following' do
    let(:user) { create :public_user }
    let(:followed) { create :partner, name: 'followed' }
    let(:not_followed) { create :partner, name: 'not followed' }

    before { Following.create!(user: user, partner: followed, active: true) }

    def serialized_following(partner, user)
      V1::PartnerSerializer.new(partner, scope: { user: user, following: true }, root: false).as_json[:following]
    end

    it 'serializes the following status of each partner without further query' do
      partners = [Partner.find(followed.id), Partner.find(not_followed.id)]
      Preloaders::Partner.preload_following(partners, user: user)

      queries = []
      callback = lambda { |*, payload| queries << payload[:sql] if payload[:sql] =~ /followings/ }

      result = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        partners.map { |partner| serialized_following(partner, user) }
      end

      expect(result).to eq([true, false])
      expect(queries).to be_empty
    end

    it 'marks every instance of a same partner' do
      partners = [Partner.find(followed.id), Partner.find(followed.id)]
      Preloaders::Partner.preload_following(partners, user: user)

      expect(partners.map(&:preloaded_following)).to eq([{ user.id => true }, { user.id => true }])
    end

    it 'falls back on a query for another user' do
      partner = Partner.find(followed.id)
      Preloaders::Partner.preload_following([partner], user: create(:public_user))

      expect(serialized_following(partner, user)).to eq(true)
    end

    it 'ignores anonymous users' do
      partner = Partner.find(followed.id)
      Preloaders::Partner.preload_following([partner], user: AnonymousUser.default_user)

      expect(partner.preloaded_following).to be_nil
    end
  end
end
