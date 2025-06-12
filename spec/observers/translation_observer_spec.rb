require 'rails_helper'

describe TranslationObserver do
  describe "action" do
    context "chat_message" do
      let!(:entourage) { create(:entourage) }
      let(:record) { create(:chat_message, messageable: entourage) }

      before { expect_any_instance_of(described_class).to receive(:action).with(:create, instance_of(ChatMessage)) }

      it { record }
    end

    context "entourage" do
      let(:record) { create(:entourage) }

      before { expect_any_instance_of(described_class).to receive(:action).with(:create, instance_of(Entourage)) }

      it { record }
    end

    context "private conversation not translated" do
      let(:record) { create(:conversation) }

      before { expect_any_instance_of(described_class).not_to receive(:action).with(:create, instance_of(Entourage)) }

      it { record }
    end

    context "neighborhood" do
      let(:record) { create(:neighborhood) }

      before { expect_any_instance_of(described_class).to receive(:action).with(:create, instance_of(Neighborhood)) }

      it { record }
    end

    context "neighborhood not translated if DISABLE_TRANSLATIONS_ON_WRITE" do
      let(:record) { create(:neighborhood) }

      before { ENV['DISABLE_TRANSLATIONS_ON_WRITE'] = "true" }
      after { ENV['DISABLE_TRANSLATIONS_ON_WRITE'] = "false" }

      before { expect_any_instance_of(described_class).not_to receive(:action).with(:create, instance_of(Neighborhood)) }

      it { record }
    end
  end
end
