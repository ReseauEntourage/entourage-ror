require 'rails_helper'

describe SlackServices::AssistantAlert do
  let(:user) { create :public_user, first_name: 'Camille', last_name: 'Dupont', phone: '+33611223344' }
  let(:message) { "Je ne me sens pas en sécurité,  rappelez-moi s'il vous plaît." }
  let(:contact) { create :public_user, first_name: 'Nadia', slack_id: 'U0NADIA' }

  def alert(kind: 'safety_signal', contact: nil)
    described_class.new(user: user, kind: kind, message: message, contact: contact)
  end

  def attachments(alert)
    alert.payload[:attachments].map { |attachment| attachment[:text] }
  end

  it 'uses the channel of the signals, as SignalUser does' do
    expect(alert.env).to eq(SlackServices::SignalUser.new(reported_user: user, reporting_user: user, message: 'm', signals: 's').env)
    expect(alert.payload_adds).to include(channel: 'channel')
  end

  it 'carries the person with the link to their profile and the exact approved message, and nothing else' do
    texts = attachments(alert)

    expect(texts).to eq([
      "Personne : Camille Dupont #{Rails.application.routes.url_helpers.admin_user_url(user.id, host: ENV['ADMIN_HOST'])}",
      "Message : #{message}",
      'Catégorie : safety_signal'
    ])
    expect(alert.payload.to_json).not_to include(user.phone)
    expect(alert.payload.to_json).not_to include(user.email.to_s) if user.email.present?
  end

  it 'warns the team alone, without naming a contact, when no contact is given' do
    %w[safety_signal negative_feedback handover].each do |kind|
      expect(alert(kind: kind).payload[:text]).to start_with('Team modération')
      expect(alert(kind: kind).payload[:text]).not_to include('<@')
    end
  end

  it 'mentions the dedicated contact, whatever the kind, when one is given that Slack can mention' do
    %w[safety_signal handover].each do |kind|
      expect(alert(kind: kind, contact: contact).payload[:text]).to start_with('<@U0NADIA> ou team modération')
      expect(alert(kind: kind, contact: contact)).to be_contact_mentioned
    end
  end

  it 'names nobody when the contact has no Slack identifier' do
    contact.update!(slack_id: nil)

    expect(alert(kind: 'handover', contact: contact).payload[:text]).to start_with('Team modération')
    expect(alert(kind: 'handover', contact: contact)).not_to be_contact_mentioned
  end

  it 'says it is a handover, with the team alone, when the person has no dedicated contact' do
    text = alert(kind: 'handover', contact: nil).payload[:text]

    expect(text).to start_with('Team modération')
    expect(text).not_to include('<@')
    expect(text).to include('Passation')
  end

  it 'refuses an unknown kind through its labels' do
    expect(described_class::KINDS).to eq(described_class::LABELS.keys)
  end
end
