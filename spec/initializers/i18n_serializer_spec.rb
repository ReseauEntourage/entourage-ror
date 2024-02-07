require 'rails_helper'

describe ActiveModel::Serializer::I18nSerializer do
  let(:serializer) { ActiveModel::Serializer::I18nSerializer.new(instance, :content, :en) }
  let(:instance) { create(:chat_message, content: "foo", status: status, translation: translation) }
  let(:translation) { create(:translation,
    from_lang: :fr,
    fr: { "content" => "foo.fr" },
    en: { "content" => "foo.en" }
  ) }

  describe "translation" do
    let(:subject) { serializer.translation }

    context "deleted" do
      let(:status) { :deleted }

      it { expect(subject).to eq("") }
    end

    context "not deleted" do
      let(:status) { :active }

      it { expect(subject).to eq("foo.en") }
    end
  end

  describe "translations" do
    let(:subject) { serializer.translations }

    context "deleted" do
      let(:status) { :deleted }

      it { expect(subject).to eq({
        translation: "",
        original: "",
        from_lang: "fr",
        to_lang: :en
      }) }
    end

    context "not deleted" do
      let(:status) { :active }

      it { expect(subject).to eq({
        translation: "foo.en",
        original: "foo",
        from_lang: "fr",
        to_lang: :en
      }) }
    end
  end
end
