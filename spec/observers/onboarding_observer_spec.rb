require 'rails_helper'

describe OnboardingObserver do
  let!(:user) { create(:public_user) }

  def event_names
    Event.where(user_id: user.id).pluck(:name)
  end

  def first_event
    Event.find_by(user_id: user.id, name: 'onboarding.outing.first_event')
  end

  def join(outing, status: JoinRequest::ACCEPTED_STATUS)
    create(:join_request, joinable: outing, user: user, status: status)
  end

  describe 'registration to an outing' do
    context 'first steps webinar' do
      let(:outing) { create(:outing, :outing_class, online: true, sf_category: :welcome_entourage_local) }

      before { join(outing) }

      it { expect(event_names).to include('onboarding.outing.webinar_or_first_steps') }
      it { expect(event_names).not_to include('onboarding.outing.first_event') }
      it { expect(event_names).not_to include('onboarding.outing.papotages') }
    end

    context 'webinar category' do
      let(:outing) { create(:outing, :outing_class, online: true, sf_category: :atelier_femmes) }

      before { join(outing) }

      it { expect(event_names).to include('onboarding.outing.webinar_or_first_steps') }
      it { expect(event_names).not_to include('onboarding.outing.first_event') }
    end

    context 'papotage' do
      let(:outing) { create(:outing, :outing_class, online: true, title: 'Papotage solidaire') }

      before { join(outing) }

      it { expect(first_event.properties).to eq('outing_type' => 'papotage') }
      it { expect(event_names).not_to include('onboarding.outing.webinar_or_first_steps') }

      # kept for the apps already installed, they read it to tick the last step
      it { expect(event_names).to include('onboarding.outing.papotages') }
    end

    context 'online event which is not a papotage' do
      let(:outing) { create(:outing, :outing_class, online: true, title: 'Atelier cuisine', sf_category: :convivialite) }

      before { join(outing) }

      it { expect(first_event.properties).to eq('outing_type' => 'visio') }
      it { expect(event_names).not_to include('onboarding.outing.papotages') }
    end

    context 'physical event' do
      let(:outing) { create(:outing, :outing_class, online: false, title: 'Balade au parc', sf_category: :convivialite) }

      before { join(outing) }

      it { expect(first_event.properties).to eq('outing_type' => 'physique') }
      it { expect(event_names).not_to include('onboarding.outing.papotages') }
      it { expect(event_names).not_to include('onboarding.outing.webinar_or_first_steps') }
    end

    context 'registration not accepted yet' do
      let(:outing) { create(:outing, :outing_class, online: false, sf_category: :convivialite) }

      before { join(outing, status: JoinRequest::PENDING_STATUS) }

      it { expect(first_event).to be_nil }
    end

    context 'second registration' do
      let(:first) { create(:outing, :outing_class, online: false, title: 'Balade au parc', sf_category: :convivialite) }
      let(:second) { create(:outing, :outing_class, online: true, title: 'Atelier cuisine', sf_category: :convivialite) }

      before do
        join(first)
        join(second)
      end

      it 'keeps the type of the first event' do
        expect(Event.where(user_id: user.id, name: 'onboarding.outing.first_event').count).to eq(1)
        expect(first_event.properties).to eq('outing_type' => 'physique')
      end
    end

    context 'webinar then another event' do
      let(:webinar) { create(:outing, :outing_class, online: true, sf_category: :welcome_entourage_local) }
      let(:other) { create(:outing, :outing_class, online: false, title: 'Balade au parc', sf_category: :convivialite) }

      before do
        join(webinar)
        join(other)
      end

      it 'validates both steps independently' do
        expect(event_names).to include('onboarding.outing.webinar_or_first_steps', 'onboarding.outing.first_event')
      end
    end
  end
end
