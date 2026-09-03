require 'rails_helper'
include AuthHelper

describe Admin::AdminNotesController do
  let!(:admin) { admin_basic_login }

  describe 'POST create' do
    context 'on a user' do
      let!(:target_user) { FactoryBot.create(:public_user, community: admin.community) }

      before do
        post :create, params: { notable_type: 'User', notable_id: target_user.id, admin_note: { body: 'À surveiller' } }
      end

      it { expect(target_user.admin_notes.count).to eq(1) }
      it { expect(target_user.admin_notes.first.body).to eq('À surveiller') }
      it { expect(target_user.admin_notes.first.author).to eq(admin) }
    end

    context 'on an entourage' do
      let!(:entourage) { FactoryBot.create(:entourage) }

      before do
        post :create, params: { notable_type: 'Entourage', notable_id: entourage.id, admin_note: { body: 'Contacté le 12/08' } }
      end

      it { expect(entourage.admin_notes.count).to eq(1) }
    end

    context 'with an unsupported notable type' do
      it 'raises RecordNotFound' do
        expect {
          post :create, params: { notable_type: 'Partner', notable_id: 1, admin_note: { body: 'x' } }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a blank body' do
      let!(:target_user) { FactoryBot.create(:public_user, community: admin.community) }

      before do
        post :create, params: { notable_type: 'User', notable_id: target_user.id, admin_note: { body: '' } }
      end

      it { expect(target_user.admin_notes.count).to eq(0) }
    end
  end

  describe 'DELETE destroy' do
    let!(:target_user) { FactoryBot.create(:public_user, community: admin.community) }
    let!(:note) { FactoryBot.create(:admin_note, notable: target_user, author: admin) }

    before { delete :destroy, params: { id: note.id } }

    it { expect(AdminNote.find_by(id: note.id)).to be_nil }
  end
end
