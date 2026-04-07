require 'rails_helper'

describe EmailPreferencesService do
  let!(:category) { create :email_category, name: :newsletter rescue PG::UniqueViolation }

  context 'when a user unsubscribes' do
    let(:user) { create :public_user }
    after { EmailPreferencesService.update_subscription(category: :newsletter, subscribed: false, user: user) }
    it {
      expect_any_instance_of(NewsletterServices::Contact).to receive(:delete)
    }
  end

  context 'when a user subscribes' do
    let(:user) { create :public_user }
    after { EmailPreferencesService.update_subscription(category: :newsletter, subscribed: true, user: user) }
    it {
      expect_any_instance_of(NewsletterServices::Contact).to receive(:create)
    }
  end
end
