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

  describe 'update_subscription when a concurrent request created the preference' do
    let(:user) { create :public_user }
    let(:other_category) { create :email_category }
    let(:category_name) { other_category.name }

    subject { EmailPreferencesService.update_subscription(category: category_name, subscribed: false, user: user) }

    before do
      # the first lookup misses the preference that another request has just inserted
      create :email_preference, user: user, category: other_category, subscribed: true

      missed = false
      allow(EmailPreference).to receive(:find_or_initialize_by).and_wrap_original do |method, attributes|
        next method.call(attributes) if missed || attributes[:email_category_id] != other_category.id

        missed = true
        EmailPreference.new(attributes)
      end
    end

    it { expect(subject).to be(true) }
    it { expect { subject }.to change { EmailPreferencesService.accepts_emails?(user: user, category: category_name) }.to(false) }

    context 'with category all' do
      let(:category_name) { :all }

      it { expect { subject }.to change { EmailPreferencesService.accepts_emails?(user: user, category: other_category.name) }.to(false) }
    end
  end
end
