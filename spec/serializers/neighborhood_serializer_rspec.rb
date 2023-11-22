require 'rails_helper'

describe V1::NeighborhoodSerializer do
  let(:user) { create(:public_user, lang: :en) }

  describe "name" do
    let!(:neighborhood) { create(:neighborhood, name: :foo) }
    let!(:translation) { create(:translation, instance: neighborhood, from_lang: :fr, en: :bar, uk: :baz) }

    let(:subject) { described_class.new(neighborhood, scope: { user: user }).name_translations }

    context "translation" do
      it { expect(subject).to eq("bar") }
    end

    context "no translation" do
      before { ENV['DISABLE_TRANSLATIONS_ON_READ'] = "true" }
      after { ENV['DISABLE_TRANSLATIONS_ON_READ'] = "false" }

      it { expect(subject).to eq("foo") }
    end
  end
end
