require 'rails_helper'

describe RecommandationServices::Completor do
  let(:user) { FactoryBot.create(:pro_user) }

  let(:completor) { RecommandationServices::Completor.new(user: user, controller_name: controller_name, action_name: action_name, params: params) }

  let(:controller_name) { "resources" }
  let(:action_name) { :index }
  let(:params) { Hash.new }

  let(:instance) { controller_name.singularize.to_sym }

  describe 'run' do
    let(:subject) { completor.run }

    describe 'arguments' do
      context 'defined arguments' do
        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:set_completed_criteria!) }

        it { subject }
      end

      context 'undefined controller_name' do
        let(:controller_name) { "foo" }

        before { expect_any_instance_of(RecommandationServices::Completor).not_to receive(:set_completed_criteria!) }

        it { subject }
      end

      context 'undefined action_name' do
        let(:action_name) { "foo" }

        before { expect_any_instance_of(RecommandationServices::Completor).not_to receive(:set_completed_criteria!) }

        it { subject }
      end

      context 'index' do
        let(:controller_name) { "neighborhoods" }
        let(:action_name) { "index" }

        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:after_index) }

        it { subject }
      end

      context 'show' do
        let(:controller_name) { "neighborhoods" }
        let(:action_name) { "show" }

        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:after_show) }
        before { expect_any_instance_of(RecommandationServices::Completor).not_to receive(:after_show_webview) }

        it { subject }
      end

      context 'show webview' do
        let(:controller_name) { "webviews" }
        let(:action_name) { "show" }

        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:after_show_webview) }

        it { subject }
      end

      context 'create' do
        let(:controller_name) { "neighborhoods" }
        let(:action_name) { "create" }

        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:after_create) }
        before { expect_any_instance_of(RecommandationServices::Completor).not_to receive(:after_create_user) }

        it { subject }
      end

      context 'join neighborhood' do
        let(:controller_name) { "users" }
        let(:action_name) { "create" }
        let(:params) { { neighborhood_id: 1 } }

        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:after_create_user_on_neighborhood) }

        it { subject }
      end

      context 'join outing' do
        let(:controller_name) { "users" }
        let(:action_name) { "create" }
        let(:params) { { outing_id: 1 } }

        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:after_create_user_on_outing) }

        it { subject }
      end

      context 'join resource' do
        let(:controller_name) { "users" }
        let(:action_name) { "create" }
        let(:params) { { resource_id: 1 } }

        before { expect_any_instance_of(RecommandationServices::Completor).to receive(:after_create_user_on_resource) }

        it { subject }
      end
    end
  end

  describe 'after_index' do
    let(:subject) { completor.after_index(instance, params) }

    it { expect(subject).to eq({ instance: :resource, action: :index }) }
  end

  describe 'after_show' do
    let(:subject) { completor.after_show(instance, params) }
    let(:params) { { id: 42 } }

    it { expect(subject).to eq({ instance: :resource, action: :show, instance_id: 42 }) }
  end

  describe 'after_show on webview' do
    let(:subject) { completor.after_show(instance, params) }
    let(:controller_name) { "webviews" }
    let(:params) { { url: "foobar" } }

    it { expect(subject).to eq({ instance: :webview, action: :show, instance_url: "foobar" }) }
  end

  describe 'after_create' do
    let(:subject) { completor.after_create(instance, params) }

    it { expect(subject).to eq({ instance: :resource, action: :create }) }
  end

  describe 'after_create on user' do
    let(:subject) { completor.after_create(instance, params) }
    let(:controller_name) { "users" }

    it { expect(subject).to be_nil }
  end

  describe 'after_create on join neighborhood' do
    let(:subject) { completor.after_create(instance, params) }
    let(:controller_name) { "users" }
    let(:params) { { neighborhood_id: 1 } }

    it { expect(subject).to eq({ instance: :neighborhood, action: :join }) }
  end

  describe 'after_create on join outing' do
    let(:subject) { completor.after_create(instance, params) }
    let(:controller_name) { "users" }
    let(:params) { { outing_id: 1 } }

    it { expect(subject).to eq({ instance: :outing, action: :join }) }
  end

  describe 'after_create on join resource' do
    let(:subject) { completor.after_create(instance, params) }
    let(:controller_name) { "users" }
    let(:params) { { resource_id: 1 } }

    it { expect(subject).to eq({ instance: :resource, action: :show, instance_id: 1 }) }
  end
end
