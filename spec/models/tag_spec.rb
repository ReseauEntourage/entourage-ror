require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe "interest_list" do
    let(:subject) { Tag.interest_list }

    it { expect(subject).to include('sport') }
  end

  describe "interests" do
    let(:subject) { Tag.interests }

    it { expect(subject).to have_key(:sport) }
    it { expect(subject[:sport]).to eq("Sport") }
  end

  describe "interests_t" do
    let(:subject) { Tag.interests_t(:fr) }

    it { expect(subject).to include({ id: :sport, name: I18n.t('tags.interests.sport') }) }
  end

  describe "sections_t" do
    let(:subject) { Tag.sections_t(:fr) }

    it { expect(subject).to include({ id: :social, name: I18n.t('tags.sections.social.name'), subname: I18n.t('tags.sections.social.subname') }) }
  end

  describe "signals_t" do
    let(:subject) { Tag.signals_t(:fr) }

    it { expect(subject).to include({ id: :spam, name: I18n.t('tags.signals.spam') }) }
  end
end
