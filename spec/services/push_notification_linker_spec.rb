require 'rails_helper'

describe PushNotificationLinker, type: :service do
  describe "get" do
    let(:subject) { PushNotificationLinker.get(object) }

    context "neighborhood" do
      let(:object) { create(:neighborhood) }

      it { expect(subject).to eq({ instance: "neighborhood", instance_id: object.id }) }
    end

    context "user" do
      let(:object) { create(:public_user) }

      it { expect(subject).to eq({ instance: "user", instance_id: object.id }) }
    end

    context "poi" do
      let(:object) { create(:poi) }

      it { expect(subject).to eq({ instance: "poi", instance_id: object.id }) }
    end

    context "resource" do
      let(:object) { create(:resource) }

      it { expect(subject).to eq({ instance: "resource", instance_id: object.id }) }
    end

    context "partner" do
      let(:object) { create(:partner) }

      it { expect(subject).to eq({ instance: "partner", instance_id: object.id }) }
    end

    context "conversation" do
      let(:object) { create(:conversation) }

      it { expect(subject).to eq({ instance: "conversation", instance_id: object.id }) }
    end

    context "outing" do
      let(:object) { create(:outing) }

      it { expect(subject).to eq({ instance: "outing", instance_id: object.id }) }
    end

    context "contribution" do
      let(:object) { create(:contribution) }

      it { expect(subject).to eq({ instance: "contribution", instance_id: object.id }) }
    end

    context "solicitation" do
      let(:object) { create(:solicitation) }

      it { expect(subject).to eq({ instance: "solicitation", instance_id: object.id }) }
    end

    context "chat_message from action" do
      let(:messageable) { create(:contribution) }
      let(:object) { create(:chat_message, messageable: messageable) }

      it { expect(subject).to eq({ instance: "conversation", instance_id: messageable.id }) }
    end

    context "chat_message from outing" do
      let(:messageable) { create(:outing) }
      let(:object) { create(:chat_message, messageable: messageable) }

      it { expect(subject).to eq({ instance: "outing_post", instance_id: messageable.id, post_id: object.id }) }
    end

    context "chat_message from neighborhood" do
      let(:messageable) { create(:neighborhood) }
      let(:object) { create(:chat_message, messageable: messageable) }

      it { expect(subject).to eq({ instance: "neighborhood_post", instance_id: messageable.id, post_id: object.id }) }
    end
  end
end
