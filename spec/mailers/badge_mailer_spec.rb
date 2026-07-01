require 'rails_helper'

describe BadgeMailer, type: :mailer do
  let(:user) { create(:public_user, goal: 'ask_for_help') }

  describe '#deactivation_warning' do
    subject(:mail) { BadgeMailer.deactivation_warning(user, badge_tag, current, 3) }

    context 'for fidele_papotages with current=2' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:current) { 2 }

      it { expect(mail['X-MJ-TemplateID'].value).to eq '8099655' }
      it { expect(mail['X-Mailjet-Campaign'].value).to eq 'badge_warning_fidele_papotages' }
      it { expect(mail.to).to eq [user.email] }

      it 'sets badge_nom from i18n' do
        vars = JSON.parse(mail['X-MJ-Vars'].value)
        expect(vars['badge_nom']).to eq I18n.t('badge_mailer.badges.fidele_papotages.name', locale: user.lang)
      end

      it 'sets progression_pct to 67' do
        vars = JSON.parse(mail['X-MJ-Vars'].value)
        expect(vars['progression_pct']).to eq 67
      end

      it 'sets progression_label from i18n' do
        vars = JSON.parse(mail['X-MJ-Vars'].value)
        expect(vars['progression_label']).to eq I18n.t('badge_mailer.badges.fidele_papotages.progression_label.2', locale: user.lang)
      end
    end

    context 'for fidele_papotages with current=1' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:current) { 1 }

      it 'sets progression_pct to 33 and progression_label for 2 remaining' do
        vars = JSON.parse(mail['X-MJ-Vars'].value)
        expect(vars['progression_pct']).to eq 33
        expect(vars['progression_label']).to eq I18n.t('badge_mailer.badges.fidele_papotages.progression_label.1', locale: user.lang)
      end
    end

    context 'for voix_presente with current=2' do
      let(:badge_tag) { 'voix_presente' }
      let(:current) { 2 }

      it 'sets badge_nom from i18n' do
        vars = JSON.parse(mail['X-MJ-Vars'].value)
        expect(vars['badge_nom']).to eq I18n.t('badge_mailer.badges.voix_presente.name', locale: user.lang)
      end
    end

    context 'for moteur_rencontres with current=1' do
      let(:badge_tag) { 'moteur_rencontres' }
      let(:current) { 1 }

      it 'sets badge_nom from i18n' do
        vars = JSON.parse(mail['X-MJ-Vars'].value)
        expect(vars['badge_nom']).to eq I18n.t('badge_mailer.badges.moteur_rencontres.name', locale: user.lang)
      end
    end

    context 'when badge_tag is not a reversible badge' do
      let(:badge_tag) { 'bienvenue' }
      let(:current) { 1 }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end

    context 'when current has no matching label (e.g. 0)' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:current) { 0 }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end

    context 'when user has no email' do
      before { user.update_column(:email, nil) }
      let(:badge_tag) { 'fidele_papotages' }
      let(:current) { 2 }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end

    context 'when user lang is :en' do
      before { allow(user).to receive(:lang).and_return(:en) }
      let(:badge_tag) { 'moteur_rencontres' }
      let(:current) { 1 }

      it 'uses English translation' do
        vars = JSON.parse(mail['X-MJ-Vars'].value)
        expect(vars['badge_nom']).to eq 'Event Creator'
        expect(vars['progression_label']).to eq '2 more events to organize this quarter'
      end
    end
  end
end
