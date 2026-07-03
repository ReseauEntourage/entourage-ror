require 'rails_helper'

describe BadgeMailer, type: :mailer do
  let(:user) { create(:public_user, goal: 'ask_for_help', lang: 'fr') }

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

  let(:awarded_at) { Time.zone.local(2026, 1, 15) }
  let(:deactivated_at) { Time.zone.local(2026, 4, 20) }

  describe '.deactivated' do
    subject(:mail) { BadgeMailer.deactivated(user, badge_tag, awarded_at, deactivated_at) }
    let(:json_variables) { JSON.parse(mail['X-MJ-Vars'].value) }

    context 'with a reversible badge (fidele_papotages)' do
      let(:badge_tag) { 'fidele_papotages' }

      it { expect(mail.message).not_to be_a ActionMailer::Base::NullMail }
      it { expect(mail['X-MJ-TemplateID'].value).to eq '8103988' }
      it { expect(mail.to).to eq [user.email] }
      it { expect(json_variables['badge_nom']).to eq 'As du papotage' }
      it { expect(json_variables['badge_duree']).to eq '3 mois' }
      it { expect(json_variables['badge_bilan']).to include('15 janvier 2026') }
      it { expect(json_variables).to have_key('badge_image_url') }
      it { expect(json_variables).to have_key('deeplink_badge') }
    end

    context 'with the other reversible badges' do
      it 'uses the correct name for voix_presente' do
        mail = BadgeMailer.deactivated(user, 'voix_presente', awarded_at, deactivated_at)
        expect(JSON.parse(mail['X-MJ-Vars'].value)['badge_nom']).to eq 'Tisseur de liens'
      end

      it 'uses the correct name for moteur_rencontres' do
        mail = BadgeMailer.deactivated(user, 'moteur_rencontres', awarded_at, deactivated_at)
        expect(JSON.parse(mail['X-MJ-Vars'].value)['badge_nom']).to eq 'Créateur de rencontres'
      end
    end

    context 'with an irreversible badge (bienvenue)' do
      let(:badge_tag) { 'bienvenue' }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end

    context 'with an irreversible badge (premier_contact)' do
      let(:badge_tag) { 'premier_contact' }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end

    context 'when the badge was held for less than 7 days' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:deactivated_at) { awarded_at + 3.days }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end

    context 'when held for exactly 7 days' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:deactivated_at) { awarded_at + 7.days }

      it { expect(mail.message).not_to be_a ActionMailer::Base::NullMail }
    end

    context 'when awarded_at is missing' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:awarded_at) { nil }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end

    context 'when the duration is less than a month' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:deactivated_at) { awarded_at + 10.days }

      it 'uses the zero-month wording' do
        expect(json_variables['badge_duree']).to eq "moins d'un mois"
      end
    end

    context 'when the duration is exactly one month' do
      let(:badge_tag) { 'fidele_papotages' }
      let(:deactivated_at) { awarded_at + 1.month }

      it 'uses the singular wording' do
        expect(json_variables['badge_duree']).to eq '1 mois'
      end
    end

    context 'when the user opted out of default emails' do
      let(:badge_tag) { 'fidele_papotages' }

      before { EmailPreferencesService.update_subscription(user: user, subscribed: false, category: :default) }

      it { expect(mail.message).to be_a ActionMailer::Base::NullMail }
    end
  end
end
