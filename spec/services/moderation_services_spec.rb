require 'rails_helper'

describe ModerationServices do
  describe '.referent_benevole_for_user' do
    let(:user) { create :public_user, :paris }
    let(:referent) { create :public_user }
    let(:default_referent) { create :admin_user, slack_id: ENV['SLACK_DEFAULT_REFERENT_ID'] }

    context 'when the user departement has a moderation area with a referent_benevole' do
      before { create :moderation_area, departement: '75', referent_benevole: referent }

      it 'returns the moderation area referent_benevole' do
        expect(ModerationServices.referent_benevole_for_user(user)).to eq referent
      end
    end

    context 'when the moderation area has no referent_benevole' do
      before do
        default_referent
        create :moderation_area, departement: '75', referent_benevole: nil
      end

      it 'returns the default referent_benevole' do
        expect(ModerationServices.referent_benevole_for_user(user)).to eq default_referent
      end
    end

    context 'when there is no moderation area for the departement' do
      before { default_referent }

      it 'falls back to the Hors-Zone referent_benevole, then to the default referent' do
        expect(ModerationServices.referent_benevole_for_user(user)).to eq default_referent
      end
    end
  end

  describe '.default_referent_benevole' do
    it 'returns the validated admin matching SLACK_DEFAULT_REFERENT_ID' do
      admin = create :admin_user, slack_id: ENV['SLACK_DEFAULT_REFERENT_ID']

      expect(ModerationServices.default_referent_benevole).to eq admin
    end

    it 'returns nil when no admin matches' do
      expect(ModerationServices.default_referent_benevole).to be_nil
    end

    context 'when SLACK_DEFAULT_REFERENT_ID is not set' do
      before { stub_const('ModerationServices::SLACK_DEFAULT_REFERENT_ID', nil) }

      it 'does not match an admin with a blank slack_id' do
        create :admin_user, slack_id: nil

        expect(ModerationServices.default_referent_benevole).to be_nil
      end
    end
  end
end
