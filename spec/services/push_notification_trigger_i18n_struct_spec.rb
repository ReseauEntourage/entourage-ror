require 'rails_helper'

describe PushNotificationTrigger::I18nStruct do
  describe 'text' do
    let(:subject) { described_class.new(text: 'username - titre')}

    it { expect(subject.to(:fr)).to eq('username - titre')}
  end

  describe 'text with args' do
    let(:subject) { described_class.new(text: 'username - %s', i18n_args: ['titre'])}

    it { expect(subject.to(:fr)).to eq('username - titre')}
  end

  describe 'text with nested args' do
    let(:subject) { described_class.new(
      text: 'username - %s',
      i18n_args: [described_class.new(text: 'titre')]
    )}

    it { expect(subject.to(:fr)).to eq('username - titre')}
  end

  describe 'i18n' do
    let(:subject) { described_class.new(i18n: 'timeliner.h1.title')}

    it { expect(subject.to(:fr)).to eq('Bienvenue chez Entourage 👌')}
  end

  describe 'i18n with args' do
    let(:subject) { described_class.new(i18n: 'push_notifications.action.create_for_follower', i18n_args: ['username', 'titre'])}

    it { expect(subject.to(:fr)).to eq('username vous invite à rejoindre titre')}
  end

  describe 'i18n with nested args' do
    let(:subject) { described_class.new(i18n: 'push_notifications.action.create_for_follower', i18n_args: ['username', described_class.new(text: 'titre')])}

    it { expect(subject.to(:fr)).to eq('username vous invite à rejoindre titre')}
  end

  describe 'instance and field' do
    let(:instance) { create(:neighborhood, name: 'foo') }
    let(:subject) { described_class.new(instance: instance, field: :name) }

    it { expect(subject.to(:fr)).to eq('foo')}
  end

  describe 'date' do
    let(:subject) { described_class.new(date: '2023-01-01'.to_date) }

    it { expect(subject.to(:fr)).to eq('1 janvier 2023') }
  end

  describe 'date as args' do
    let(:subject) { described_class.new(text: 'date is %s', i18n_args: [described_class.new(date: '2023-01-01'.to_date)]) }

    it { expect(subject.to(:fr)).to eq('date is 1 janvier 2023') }
  end
end
