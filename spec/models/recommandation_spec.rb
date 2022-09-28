require 'rails_helper'

RSpec.describe Recommandation, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:instance) }
  it { should validate_presence_of(:action) }

  describe 'matches' do
    let(:recommandation) { FactoryBot.create(:recommandation, name: :foo, instance: instance, action: action, argument_value: argument_value) }
    let(:instance) { :resource }
    let(:action) { :index }
    let(:argument_value) { nil }

    let(:subject) { recommandation.matches(criteria) }

    context 'show webview' do
      let(:instance) { :webview }
      let(:action) { :show }
      let(:argument_value) { "path/to/webview" }

      let(:criteria) { [{ "instance" => "webview", "action" => "show", "instance_id" => nil, "instance_url" => "path/to/webview"}] }

      it { expect(subject).to be(true) }
    end

    context 'show webview wrong url' do
      let(:instance) { :webview }
      let(:action) { :show }
      let(:argument_value) { "path/to/foo" }

      let(:criteria) { [{ "instance" => "webview", "action" => "show", "instance_id" => nil, "instance_url" => "path/to/webview"}] }

      it { expect(subject).to be(false) }
    end

    context 'show webview wrong parameter for url' do
      let(:instance) { :webview }
      let(:action) { :show }
      let(:argument_value) { "path/to/webview" }

      let(:criteria) { [{ "instance" => "webview", "action" => "show", "instance_id" => "path/to/webview", "instance_url" => nil}] }

      it { expect(subject).to be(false) }
    end

    context 'show webview wrong instance' do
      let(:instance) { :webview }
      let(:action) { :show }
      let(:argument_value) { "path/to/webview" }

      let(:criteria) { [{ "instance" => "resource", "action" => "show", "instance_id" => nil, "instance_url" => "path/to/webview"}] }

      it { expect(subject).to be(false) }
    end

    context 'show resource' do
      let(:instance) { :resource }
      let(:action) { :show }
      let(:argument_value) { "42" }

      let(:criteria) { [{ "instance" => "resource", "action" => "show", "instance_id" => 42, "instance_url" => nil }] }

      it { expect(subject).to be(true) }
    end

    context 'show resource wrong id' do
      let(:instance) { :resource }
      let(:action) { :show }
      let(:argument_value) { "1" }

      let(:criteria) { [{ "instance" => "resource", "action" => "show", "instance_id" => 42, "instance_url" => nil }] }

      it { expect(subject).to be(false) }
    end

    context 'show resource wrong instance' do
      let(:instance) { :resource }
      let(:action) { :show }
      let(:argument_value) { "42" }

      let(:criteria) { [{ "instance" => "webview", "action" => "show", "instance_id" => 42, "instance_url" => nil }] }

      it { expect(subject).to be(false) }
    end

    context 'show_joined neighborhood' do
      let(:instance) { :neighborhood }
      let(:action) { :show_joined }

      let(:criteria) { [{ "instance" => "neighborhood", "action" => "show", "instance_id" => :foo, "instance_url" => :bar }] }

      it { expect(subject).to be(true) }
    end

    context 'show_not_joined neighborhood' do
      let(:instance) { :neighborhood }
      let(:action) { :show_not_joined }

      let(:criteria) { [{ "instance" => "neighborhood", "action" => "show", "instance_id" => :foo, "instance_url" => :bar }] }

      it { expect(subject).to be(true) }
    end

    context 'show_not_joined neighborhood wrong instance' do
      let(:instance) { :neighborhood }
      let(:action) { :show_not_joined }

      let(:criteria) { [{ "instance" => "resource", "action" => "show", "instance_id" => :foo, "instance_url" => :bar }] }

      it { expect(subject).to be(false) }
    end

    context 'create neighborhood' do
      let(:instance) { :neighborhood }
      let(:action) { :create }

      let(:criteria) { [{ "instance" => "neighborhood", "action" => "create", "instance_id" => :foo, "instance_url" => :bar }] }

      it { expect(subject).to be(true) }
    end

    context 'index neighborhood' do
      let(:instance) { :neighborhood }
      let(:action) { :index }

      let(:criteria) { [{ "instance" => "neighborhood", "action" => "index", "instance_id" => :foo, "instance_url" => :bar }] }

      it { expect(subject).to be(true) }
    end

    context 'multi criteria' do
      let(:instance) { :resource }
      let(:action) { :show }
      let(:argument_value) { "23" }

      let(:criteria) { [
        { "action" => "index", "instance" => "resource", "instance_id" => nil, "instance_url" => nil },
        { "action" => "show", "instance" => "resource", "instance_id" => 18, "instance_url" => nil },
        { "action" => "show", "instance" => "resource", "instance_id" => 23, "instance_url" => nil }
      ]}

      it { expect(subject).to be(true) }
    end
  end
end
