require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '#count_or_unknown' do
    let(:user) { create(:public_user) }
    let(:relation) { ChatMessage.where(user_id: user.id) }

    it { expect(helper.count_or_unknown(relation)).to eq(0) }

    context 'when the count reaches the statement timeout' do
      before { allow(relation).to receive(:count).and_raise(ActiveRecord::QueryCanceled) }

      it { expect(helper.count_or_unknown(relation)).to eq('?') }
    end
  end
end
