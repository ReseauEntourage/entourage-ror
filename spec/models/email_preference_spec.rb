require 'rails_helper'

describe EmailPreference, type: :model do
  describe 'subscription_changed_at' do
    let(:created_at) { 3.days.ago.change(usec: 0) }
    let(:updated_at) { 1.minute.ago.change(usec: 0) }
    let(:preference) { Timecop.freeze(created_at) { create :email_preference } }

    context 'on create' do
      it { expect(preference.subscription_changed_at).to eq created_at }
    end

    context "on update when subscribed doesn't change" do
      subject do
        Timecop.freeze(updated_at) do
          preference.update(subscribed: preference.subscribed)
        end
      end

      it do
        expect { subject }
        .not_to change { preference.reload.subscription_changed_at }
        .from(created_at)
      end
    end

    context 'on update when subscribed changes' do
      subject do
        Timecop.freeze(updated_at) do
          preference.update(subscribed: !preference.subscribed)
        end
      end

      it do
        expect { subject }
        .to change { preference.reload.subscription_changed_at }
        .to(updated_at)
      end
    end
  end
end
