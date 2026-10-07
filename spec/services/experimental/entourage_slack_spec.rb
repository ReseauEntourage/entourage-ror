require 'rails_helper'

describe Experimental::EntourageSlack do
  # the user lives in Paris (75) and creates a content in Gironde (33)
  let(:user) { create :public_user, :paris }

  let(:moderator_75) { create :public_user, slack_id: 'U75' }
  let(:moderator_33) { create :public_user, slack_id: 'U33' }

  let(:slack_app_webhooks) { { prefix: 'https://hooks.slack.com/', default: 'DEFAULT', '75': 'C75', '33': 'C33' }.to_json }
  let(:slack_notifier) { instance_double(Slack::Notifier, ping: nil) }

  before do
    create :moderation_area, departement: '75', animator: moderator_75, sourcing: moderator_75
    create :moderation_area, departement: '33', animator: moderator_33, sourcing: moderator_33

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('SLACK_APP_WEBHOOKS').and_return(slack_app_webhooks)
    allow(Slack::Notifier).to receive(:new).and_return(slack_notifier)
    allow(EntourageServices::GeocodingService).to receive(:search_postal_code).and_return(['FR', '33000', 'Bordeaux'])
  end

  # the creation of the content (let!) notifies Slack

  shared_examples 'channel and moderator of the content departement' do
    it 'posts in the channel of the content departement' do
      expect(Slack::Notifier).to have_received(:new).with('https://hooks.slack.com/C33')
    end

    it 'mentions the moderator of the content departement' do
      expect(slack_notifier).to have_received(:ping) do |payload|
        expect(payload[:attachments].first[:text]).to include('<@U33>')
        expect(payload[:attachments].first[:text]).not_to include('<@U75>')
      end
    end
  end

  context 'when the content is an action' do
    let!(:entourage) { create :entourage, user: user, country: 'FR', postal_code: '33000' }

    include_examples 'channel and moderator of the content departement'
  end

  context 'when the content is an outing' do
    let!(:entourage) { create :outing, user: user, country: 'FR', postal_code: '33000' }

    include_examples 'channel and moderator of the content departement'

    it 'mentions the moderator of the content departement in the subtitle' do
      expect(slack_notifier).to have_received(:ping) do |payload|
        expect(payload[:attachments].first[:author_name]).to include('<@U33>')
      end
    end
  end

  context 'when the content is outside of France' do
    let!(:entourage) { create :entourage, user: user, country: 'BE', postal_code: '1000' }

    it 'posts in the default channel' do
      expect(Slack::Notifier).to have_received(:new).with('https://hooks.slack.com/DEFAULT')
    end

    it 'does not mention the moderator of the user departement' do
      expect(slack_notifier).to have_received(:ping) do |payload|
        expect(payload[:attachments].first[:text]).to include("<@#{ModerationServices::DEFAULT_SLACK_MODERATOR_ID}>")
      end
    end
  end

  # as at creation by the app: the country is set later on by EntourageServices::GeocodingService
  context 'when the content is not geocoded yet' do
    let!(:entourage) { create :entourage, user: user, country: nil, postal_code: nil }

    it 'geocodes the content' do
      expect(entourage.reload).to have_attributes(country: 'FR', postal_code: '33000')
    end

    include_examples 'channel and moderator of the content departement'
  end

  context 'when the content is not geocoded yet and the geocoding fails' do
    before do
      allow(EntourageServices::GeocodingService).to receive(:search_postal_code).and_raise(Geocoder::ServiceUnavailable)
      allow(Sentry).to receive(:capture_exception)
    end

    let!(:entourage) { create :entourage, user: user, country: nil, postal_code: nil }

    it 'notifies anyway, in the default channel' do
      expect(Slack::Notifier).to have_received(:new).with('https://hooks.slack.com/DEFAULT')
    end

    it 'reports the error' do
      expect(Sentry).to have_received(:capture_exception).with(Geocoder::ServiceUnavailable)
    end
  end
end
