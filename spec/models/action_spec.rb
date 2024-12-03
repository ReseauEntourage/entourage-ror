require 'rails_helper'

RSpec.describe Action, type: :model do
  let(:user) { create(:user) }
  let(:action) { create(:contribution, user: user) }
  let!(:match) { create(:resource) }
  let(:other_match) { create(:resource) }

  let!(:matching_with_notification) { create(:matching, instance: action, match: match) }
  let!(:matching_without_notification) { create(:matching, instance: action, match: other_match) }

  let!(:inapp_notification) {
    create(:inapp_notification, user: user, instance: :resource, instance_id: match.id, context: :matching_on_create)
  }

  describe '#matchings_with_notifications' do
    subject { action.matchings_with_notifications }

    it 'returns matchings with inapp_notification_exists set to true when notification exists' do
      result = subject.find { |m| m.id == matching_with_notification.id }
      expect(result.inapp_notification_exists).to be_truthy
    end

    it 'returns matchings with inapp_notification_exists set to false when no notification exists' do
      result = subject.find { |m| m.id == matching_without_notification.id }
      expect(result.inapp_notification_exists).to be_falsey
    end

    context "without matchings" do
      let(:matching_with_notification) { nil }
      let(:matching_without_notification) { nil }

      it 'does not raise errors when no matchings exist' do
        expect { subject }.not_to raise_error
        expect(subject.to_a).to be_empty
      end
    end
  end
end
