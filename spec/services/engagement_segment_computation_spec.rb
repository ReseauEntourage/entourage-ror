require 'rails_helper'

RSpec.describe EngagementSegmentComputation do
  def result_for(user)
    EngagementSegmentComputation.call.find { |r| r.user_id == user.id }
  end

  def engagement(user, type, date: Date.current)
    create(:denorm_daily_engagements_with_type, user: user, engagement_type: type, date: date)
  end

  def session(user, date:)
    create(:session_history, user: user, date: date)
  end

  let(:user) { create(:user, last_sign_in_at: 1.day.ago, targeting_profile: nil, deleted: false) }

  describe 'classification' do
    context 'two or more strong (N3) events' do
      before do
        engagement(user, 'create_group')
        engagement(user, 'create_action')
      end

      it { expect(result_for(user).segment).to eq('Pilier') }
    end

    context 'exactly one strong (N3) event' do
      before { engagement(user, 'join_event') }

      it 'is Contributeur, not Pilier (ordering matters)' do
        expect(result_for(user).segment).to eq('Contributeur')
      end
    end

    context 'two or more medium (N2) events, no strong events' do
      before do
        engagement(user, 'post_message')
        engagement(user, 'smalltalk')
      end

      it { expect(result_for(user).segment).to eq('Contributeur') }
    end

    context 'exactly one medium (N2) event, no strong events' do
      before { engagement(user, 'post_group') }

      it { expect(result_for(user).segment).to eq('Observateur') }
    end

    context 'only light (N1) events' do
      before do
        engagement(user, 'reaction')
        engagement(user, 'survey')
      end

      it { expect(result_for(user).segment).to eq('Curieux') }
    end

    context 'no engagement, more than one lifetime session' do
      before do
        session(user, date: 5.days.ago.to_date)
        session(user, date: 4.days.ago.to_date)
      end

      it { expect(result_for(user).segment).to eq('Silencieux') }
    end

    context 'no engagement, at most one lifetime session' do
      before { session(user, date: 5.days.ago.to_date) }

      it 'is unclassified (nil), not Silencieux' do
        expect(result_for(user).segment).to be_nil
        expect(result_for(user).sub_segment).to be_nil
      end
    end
  end

  describe 'sub-segmentation (Silencieux only)' do
    before do
      session(user, date: 5.days.ago.to_date)
      session(user, date: 4.days.ago.to_date)
    end

    context 'user has engagement history before the 30-day window' do
      before { engagement(user, 'reaction', date: 40.days.ago.to_date) }

      it 'is Dormant' do
        expect(result_for(user).segment).to eq('Silencieux')
        expect(result_for(user).sub_segment).to eq('Dormant')
      end
    end

    context 'user has never engaged' do
      it 'is À activer' do
        expect(result_for(user).segment).to eq('Silencieux')
        expect(result_for(user).sub_segment).to eq('À activer')
      end
    end

    context 'user is not Silencieux' do
      before { engagement(user, 'reaction') }

      it 'has no sub-segment' do
        expect(result_for(user).segment).to eq('Curieux')
        expect(result_for(user).sub_segment).to be_nil
      end
    end
  end

  describe 'eligibility' do
    it 'excludes users whose last sign-in is older than 30 days' do
      inactive = create(:user, last_sign_in_at: 40.days.ago)
      engagement(inactive, 'reaction')

      expect(result_for(inactive)).to be_nil
    end

    it 'excludes deleted users' do
      deleted_user = create(:user, last_sign_in_at: 1.day.ago, deleted: true)
      engagement(deleted_user, 'reaction')

      expect(result_for(deleted_user)).to be_nil
    end

    it 'excludes team-targeted users' do
      staff_partner = create(:partner, staff: true)
      team_user = create(:user, last_sign_in_at: 1.day.ago, targeting_profile: 'team', partner: staff_partner)
      engagement(team_user, 'reaction')

      expect(result_for(team_user)).to be_nil
    end

    it 'includes users with no targeting_profile set (NULL is not team)' do
      engagement(user, 'reaction')

      expect(result_for(user)).not_to be_nil
      expect(result_for(user).segment).to eq('Curieux')
    end
  end

  describe 'session counting' do
    it 'counts sessions over the user lifetime, not just the last 30 days' do
      session(user, date: 40.days.ago.to_date)
      session(user, date: 35.days.ago.to_date)

      expect(result_for(user).segment).to eq('Silencieux')
    end
  end
end
