require 'rails_helper'

describe PushNotificationTrigger::I18nStruct do
  describe "text" do
    let(:subject) { described_class.new(text: "username - titre")}

    it { expect(subject.to(:fr)).to eq("username - titre")}
  end

  describe "text with args" do
    let(:subject) { described_class.new(text: "username - %s", i18n_args: ["titre"])}

    it { expect(subject.to(:fr)).to eq("username - titre")}
  end

  describe "text with nested args" do
    let(:subject) { described_class.new(
      text: "username - %s",
      i18n_args: [described_class.new(text: "titre")]
    )}

    it { expect(subject.to(:fr)).to eq("username - titre")}
  end

  describe "i18n" do
    let(:subject) { described_class.new(i18n: "timeliner.h1.title")}

    it { expect(subject.to(:fr)).to eq("Bienvenue chez Entourage 👌")}
  end

  describe "i18n with args" do
    let(:subject) { described_class.new(i18n: "push_notifications.action.create_for_follower", i18n_args: ["username", "titre"])}

    it { expect(subject.to(:fr)).to eq("username vous invite à rejoindre titre")}
  end

  describe "i18n with nested args" do
    let(:subject) { described_class.new(i18n: "push_notifications.action.create_for_follower", i18n_args: ["username", described_class.new(text: "titre")])}

    it { expect(subject.to(:fr)).to eq("username vous invite à rejoindre titre")}
  end

  describe "instance and field" do
    let(:instance) { create(:neighborhood, name: "foo") }
    let(:subject) { described_class.new(instance: instance, field: :name) }

    it { expect(subject.to(:fr)).to eq("foo")}
  end
end
