require 'rails_helper'

RSpec.describe ConversationsHelper, type: :helper do
  describe '#conversation_recipients_display_names' do
    let(:users) { %w(Zoé Émile adèle Bruno Chloé).map { |first_name| create :public_user, first_name: first_name, last_name: 'Martin' } }
    let(:recipient_ids) { users.map(&:id) }

    it 'returns the same names with preloaded users' do
      preloaded = User.where(id: recipient_ids + [create(:public_user).id]).select(:id, :first_name, :last_name).order(:first_name).to_a

      [1, 3, 5].each do |max|
        expect(helper.conversation_recipients_display_names(recipient_ids, max: max, users: preloaded))
          .to eq(helper.conversation_recipients_display_names(recipient_ids, max: max))
      end
    end

    it 'mentions the other recipients' do
      expect(helper.conversation_recipients_display_names(recipient_ids).last).to eq(['2 autres personnes', nil])
    end
  end
end
