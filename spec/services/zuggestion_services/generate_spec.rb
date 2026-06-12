require 'rails_helper'

describe ZuggestionServices::Generate do
  # User with a primary address at a given postal_code
  def create_user_with_address(postal_code: '75020', goal: nil, targeting_profile: nil, **attrs)
    user = create(:public_user, goal: goal, targeting_profile: targeting_profile, **attrs)
    create(:address, user: user, postal_code: postal_code, position: 1)
    user
  end

  # Make a user appear active in the pool via login_histories
  def make_active(user)
    create(:login_history, user: user, connected_at: 1.day.ago)
  end

  # Record N distinct engagement types (sets segment)
  # 0=silencieux, 1-2=curieux, 3-4=observateur, 5-6=contributeur, 7+=pilier
  def create_engagements(user, count)
    types = %w[reaction chat_message join_request post comment action invite event]
    types.first([count, types.size].min).each do |type|
      create(:denorm_daily_engagements_with_type, user: user, engagement_type: type, date: 1.day.ago)
    end
  end

  # Valid interest tags from Tag.interest_list
  VALID_INTERESTS = %w[sport cuisine culture nature].freeze

  # -------------------------------------------------------------------------
  describe '.for_user' do
    let(:user) { create_user_with_address }

    context 'when no connection candidate exists' do
      it 'returns nil for connection' do
        result = described_class.for_user(user)
        expect(result[:connection]).to be_nil
      end
    end

    context 'when a candidate exists' do
      let!(:candidate) { create_user_with_address }
      before { make_active(candidate) }

      it 'returns a connection suggestion' do
        result = described_class.for_user(user)
        expect(result[:connection]).to be_a(UserZuggestion)
      end
    end
  end

  # -------------------------------------------------------------------------
  describe '.generate_connection' do
    subject(:generate) { described_class.generate_connection(user) }

    context 'when user has no primary address' do
      let(:user) { create(:public_user) }

      it { is_expected.to be_nil }
    end

    context 'when pool is empty' do
      let(:user) { create_user_with_address(postal_code: '99999') }

      it 'returns nil when no active members share the postal_code' do
        is_expected.to be_nil
      end
    end

    context 'with a valid candidate pool' do
      let(:user)       { create_user_with_address(postal_code: '75020') }
      let!(:candidate) { create_user_with_address(postal_code: '75020') }

      before { make_active(candidate) }

      it 'creates and returns a UserZuggestion of type connection' do
        suggestion = generate
        expect(suggestion).to be_a(UserZuggestion)
        expect(suggestion.suggestion_type).to eq('connection')
        expect(suggestion.suggested_user_id).to eq(candidate.id)
      end

      it 'sets expires_at to 7 days from now' do
        suggestion = generate
        expect(suggestion.expires_at).to be_within(1.minute).of(7.days.from_now)
      end

      it 'excludes deleted candidates' do
        candidate.update!(deleted: true)
        expect(generate).to be_nil
      end

      it 'excludes the user themselves' do
        expect(described_class.generate_connection(candidate)).to be_nil
      end
    end

    # -------------------------------------------------------------------------
    context 'exclusions' do
      let(:user)       { create_user_with_address(postal_code: '75020') }
      let!(:candidate) { create_user_with_address(postal_code: '75020') }

      before { make_active(candidate) }

      it 'excludes candidates already in a conversation with the user' do
        conversation = create(:entourage, group_type: 'conversation', status: 'open')
        create(:join_request, user: user,      joinable: conversation, status: 'accepted')
        create(:join_request, user: candidate, joinable: conversation, status: 'accepted')

        expect(generate).to be_nil
      end

      it 'excludes candidates already dismissed by the user' do
        create(:user_zuggestion, user: user, suggestion_type: 'connection',
               suggested_user: candidate, dismissed_at: 1.day.ago,
               reason: 'zone', reason_type: 'zone', expires_at: 7.days.from_now)

        expect(generate).to be_nil
      end
    end

    # -------------------------------------------------------------------------
    context 'Signal 1 — même événement (+3)' do
      let(:user)       { create_user_with_address(postal_code: '75020') }
      let!(:candidate) { create_user_with_address(postal_code: '75020') }
      let!(:other)     { create_user_with_address(postal_code: '75020') }
      let!(:outing)    { create(:outing, :outing_class) }

      before do
        make_active(candidate)
        make_active(other)
        create(:join_request, user: user,      joinable: outing, status: 'accepted', created_at: 5.days.ago)
        create(:join_request, user: candidate, joinable: outing, status: 'accepted', created_at: 5.days.ago)
      end

      it 'prefers the candidate who attended the same outing' do
        suggestion = generate
        expect(suggestion.suggested_user_id).to eq(candidate.id)
      end

      it 'sets reason to the event message' do
        suggestion = generate
        expect(suggestion.reason).to include("événement")
      end
    end

    # -------------------------------------------------------------------------
    context 'Signal 2 — complémentarité de profil (+2)' do
      let(:user)       { create_user_with_address(postal_code: '75020', goal: 'ask_for_help') }
      let!(:candidate) { create_user_with_address(postal_code: '75020', goal: 'offer_help') }
      let!(:other)     { create_user_with_address(postal_code: '75020') }

      before do
        make_active(candidate)
        make_active(other)
      end

      it 'prefers the complementary-profile candidate' do
        suggestion = generate
        expect(suggestion.suggested_user_id).to eq(candidate.id)
      end

      it 'sets the riverain reason when user is PI' do
        suggestion = generate
        expect(suggestion.reason).to include("riverain")
      end

      it 'sets the integration reason when user is Riverain' do
        user.update!(goal: 'offer_help')
        candidate.update!(goal: 'ask_for_help')
        suggestion = generate
        expect(suggestion.reason).to include("intégrer")
      end
    end

    # -------------------------------------------------------------------------
    context 'Signal 3 — intérêts communs (+1 à +3)' do
      let(:user)       { create_user_with_address(postal_code: '75020') }
      let!(:candidate) { create_user_with_address(postal_code: '75020') }
      let!(:other)     { create_user_with_address(postal_code: '75020') }

      before do
        make_active(candidate)
        make_active(other)
        user.interest_list.add(*VALID_INTERESTS.first(3))
        user.save!
        candidate.interest_list.add(*VALID_INTERESTS.first(3))
        candidate.save!
      end

      it 'prefers the candidate with shared interests' do
        suggestion = generate
        expect(suggestion.suggested_user_id).to eq(candidate.id)
      end

      it "sets the reason to centres d'intérêt" do
        suggestion = generate
        expect(suggestion.reason).to include("intérêt")
      end

      it 'caps the interest score at 3 points regardless of shared count' do
        candidate.interest_list.add(VALID_INTERESTS.last)
        candidate.save!
        suggestion = generate
        expect(suggestion.suggested_user_id).to eq(candidate.id)
      end

      it 'does not fire the signal when user has no interests' do
        user.interest_list.clear
        user.save!
        suggestion = generate
        expect(suggestion.reason).to include("quartier")
      end
    end

    # -------------------------------------------------------------------------
    context 'Signal 4 — complémentarité d\'engagement (+2)' do
      let(:user)       { create_user_with_address(postal_code: '75020') }
      let!(:candidate) { create_user_with_address(postal_code: '75020') }
      let!(:other)     { create_user_with_address(postal_code: '75020') }

      before do
        make_active(candidate)
        make_active(other)
        create_engagements(candidate, 7) # Pilier
      end

      context 'Silencieux (0 engagement) → Pilier' do
        before { create_engagements(user, 0) }

        it 'selects the high-engagement candidate' do
          suggestion = generate
          expect(suggestion.suggested_user_id).to eq(candidate.id)
        end

        it 'sets the engagement reason' do
          suggestion = generate
          expect(suggestion.reason).to include("actif")
        end
      end

      context 'Observateur (3-4 engagements) → Pilier' do
        before { create_engagements(user, 3) }

        it 'selects the high-engagement candidate' do
          suggestion = generate
          expect(suggestion.suggested_user_id).to eq(candidate.id)
        end
      end

      context 'Curieux (1-2 engagements) → Pilier — signal NON déclenché' do
        before { create_engagements(user, 2) }

        it 'does not always return the engagement reason' do
          reasons = 10.times.map { described_class.generate_connection(user)&.reason }
          expect(reasons.compact.any? { |r| !r.include?("actif") }).to be(true)
        end
      end

      context 'Contributeur (5-6 engagements) → Pilier — signal NON déclenché (HIGH→HIGH)' do
        before { create_engagements(user, 5) }

        it 'does not fire the engagement signal for a high-engagement user' do
          reasons = 5.times.map { described_class.generate_connection(user)&.reason }
          expect(reasons.compact.any? { |r| !r.include?("actif") }).to be(true)
        end
      end
    end

    # -------------------------------------------------------------------------
    context 'priorité des raisons affichées' do
      let(:user)       { create_user_with_address(postal_code: '75020', goal: 'ask_for_help') }
      let!(:candidate) { create_user_with_address(postal_code: '75020', goal: 'offer_help') }

      before { make_active(candidate) }

      it 'affiche événement en priorité même si profil est aussi actif' do
        outing = create(:outing, :outing_class)
        create(:join_request, user: user,      joinable: outing, status: 'accepted', created_at: 5.days.ago)
        create(:join_request, user: candidate, joinable: outing, status: 'accepted', created_at: 5.days.ago)

        suggestion = generate
        expect(suggestion.reason).to include("événement")
      end

      it 'affiche profil si pas d\'événement' do
        suggestion = generate
        expect(suggestion.reason).to include("riverain").or include("intégrer")
      end

      it 'affiche intérêts si ni événement ni profil' do
        user.update!(goal: nil)
        candidate.update!(goal: nil)
        user.interest_list.add('sport'); user.save!
        candidate.interest_list.add('sport'); candidate.save!

        suggestion = generate
        expect(suggestion.reason).to include("intérêt")
      end

      it 'affiche quartier en fallback si aucun signal actif' do
        user.update!(goal: nil)
        candidate.update!(goal: nil)

        suggestion = generate
        expect(suggestion.reason).to include("quartier")
      end
    end
  end

  # -------------------------------------------------------------------------
  describe '.generate_next_step' do
    subject(:generate) { described_class.generate_next_step(user) }

    context 'Silencieux (0 engagement)' do
      let(:user) { create_user_with_address(postal_code: '75020') }

      context 'when a nearby outing exists in the next 7 days' do
        let!(:outing) do
          create(:outing, :outing_class, postal_code: '75020',
                 metadata: { starts_at: 3.days.from_now.iso8601,
                             ends_at: 3.days.from_now.advance(hours: 2).iso8601,
                             place_name: 'Café test',
                             street_address: '1 rue de la Paix, 75020 Paris',
                             google_place_id: 'abc123' })
        end

        it 'suggests joining the event' do
          suggestion = generate
          expect(suggestion.suggested_action).to eq('join_event')
          expect(suggestion.suggested_entourage_id).to eq(outing.id)
        end
      end

      context 'when no outing but an active neighborhood group exists' do
        let!(:group) { create(:neighborhood, postal_code: '75020') }

        it 'suggests joining the group' do
          suggestion = generate
          expect(suggestion.suggested_action).to eq('join_group')
        end
      end

      context 'when no outing and no group but an active member exists' do
        let!(:neighbor) { create_user_with_address(postal_code: '75020') }

        before { make_active(neighbor) }

        it 'suggests saying hello to an active member' do
          suggestion = generate
          expect(suggestion.suggested_action).to eq('say_hello')
        end
      end

      context 'when no content is available' do
        it { is_expected.to be_nil }
      end
    end

    context 'Curieux (1-2 engagements)' do
      let(:user) { create_user_with_address(postal_code: '75020') }

      before { create_engagements(user, 2) }

      context 'when user belongs to a group but has not posted' do
        let!(:group) { create(:neighborhood) }

        before do
          create(:join_request, user: user, joinable: group, status: 'accepted')
        end

        it 'suggests writing in the silent group' do
          suggestion = generate
          expect(suggestion.suggested_action).to eq('write_group')
          expect(suggestion.suggested_entourage_id).to eq(group.id)
        end
      end

      context 'when user has already posted in all groups' do
        let!(:group)  { create(:neighborhood) }
        let!(:outing) do
          create(:outing, :outing_class, postal_code: '75020',
                 metadata: { starts_at: 3.days.from_now.iso8601,
                             ends_at: 3.days.from_now.advance(hours: 2).iso8601,
                             place_name: 'Café test',
                             street_address: '1 rue de la Paix, 75020 Paris',
                             google_place_id: 'abc123' })
        end

        before do
          create(:join_request, user: user, joinable: group, status: 'accepted')
          create(:chat_message, user: user, messageable: group, created_at: 1.day.ago)
        end

        it 'falls back to suggesting an event' do
          suggestion = generate
          expect(suggestion.suggested_action).to eq('join_event')
        end
      end
    end

    context 'Observateur (3-4 engagements)' do
      let(:user) { create_user_with_address }

      before { create_engagements(user, 3) }

      it 'suggests creating an action' do
        suggestion = generate
        expect(suggestion.suggested_action).to eq('create_action')
      end
    end

    context 'Contributeur (5-6 engagements)' do
      let(:user) { create_user_with_address }

      before { create_engagements(user, 5) }

      context 'when a new member recently joined a shared group' do
        let!(:group)      { create(:neighborhood) }
        let!(:new_member) { create(:public_user) }

        before do
          create(:join_request, user: user,       joinable: group, status: 'accepted')
          create(:join_request, user: new_member, joinable: group, status: 'accepted',
                 created_at: 2.days.ago)
        end

        it 'suggests welcoming the new member' do
          suggestion = generate
          expect(suggestion.suggested_action).to eq('welcome_member')
          expect(suggestion.suggested_user_id).to eq(new_member.id)
        end
      end

      context 'when no new members exist' do
        it { is_expected.to be_nil }
      end
    end

    context 'Pilier (7+ engagements)' do
      let(:user) { create_user_with_address }

      before { create_engagements(user, 7) }

      it 'suggests creating an event' do
        suggestion = generate
        expect(suggestion.suggested_action).to eq('create_event')
      end
    end
  end
end
