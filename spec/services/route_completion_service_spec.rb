require 'rails_helper'

describe RouteCompletionService do
  let(:user) { FactoryBot.create(:pro_user) }

  let(:completor) { RouteCompletionService.new(user: user, controller_name: controller_name, action_name: action_name, params: params) }

  let(:controller_name) { "resources" }
  let(:action_name) { :index }
  let(:params) { Hash.new }

  let(:instance) { controller_name.singularize.to_sym }

  describe 'run_notifications' do
    let(:subject) { completor.run_notifications }

    let!(:inapp_notification) { create(:inapp_notification, user: user) }
    let!(:inapp_notification_1) { create(:inapp_notification, user: user) }

    let(:controller_name) { "neighborhoods" }
    let(:action_name) { :show }
    let(:params) { { id: inapp_notification.instance_id } }

    before { subject }

    it { expect(inapp_notification.reload.completed_at).to be_a(ActiveSupport::TimeWithZone) }
    it { expect(inapp_notification_1.reload.completed_at).to be(nil) }
  end

  describe 'run_recommandations' do
    let(:subject) { completor.run_recommandations }

    describe 'arguments' do
      context 'defined arguments' do
        before { expect_any_instance_of(RouteCompletionService).to receive(:set_completed_recommandation!) }

        it { subject }
      end

      context 'undefined controller_name' do
        let(:controller_name) { "foo" }

        before { expect_any_instance_of(RouteCompletionService).not_to receive(:set_completed_recommandation!) }

        it { subject }
      end

      context 'undefined action_name' do
        let(:action_name) { "foo" }

        before { expect_any_instance_of(RouteCompletionService).not_to receive(:set_completed_recommandation!) }

        it { subject }
      end

      context 'index' do
        let(:controller_name) { "neighborhoods" }
        let(:action_name) { "index" }

        before { expect_any_instance_of(RouteCompletionService).to receive(:after_index) }

        it { subject }
      end

      context 'show' do
        let(:controller_name) { "neighborhoods" }
        let(:action_name) { "show" }

        before { expect_any_instance_of(RouteCompletionService).to receive(:after_show) }
        before { expect_any_instance_of(RouteCompletionService).not_to receive(:after_show_webview) }

        it { subject }
      end

      context 'show webview' do
        let(:controller_name) { "webviews" }
        let(:action_name) { "show" }

        before { expect_any_instance_of(RouteCompletionService).to receive(:after_show_webview) }

        it { subject }
      end

      context 'create' do
        let(:controller_name) { "neighborhoods" }
        let(:action_name) { "create" }

        before { expect_any_instance_of(RouteCompletionService).to receive(:after_create) }
        before { expect_any_instance_of(RouteCompletionService).not_to receive(:after_create_user) }

        it { subject }
      end

      context 'join neighborhood' do
        let(:controller_name) { "users" }
        let(:action_name) { "create" }
        let(:params) { { neighborhood_id: 1 } }

        before { expect_any_instance_of(RouteCompletionService).to receive(:after_create_user_on_neighborhood) }

        it { subject }
      end

      context 'join outing' do
        let(:controller_name) { "users" }
        let(:action_name) { "create" }
        let(:params) { { outing_id: 1 } }

        before { expect_any_instance_of(RouteCompletionService).to receive(:after_create_user_on_outing) }

        it { subject }
      end

      context 'join resource' do
        let(:controller_name) { "users" }
        let(:action_name) { "create" }
        let(:params) { { resource_id: 1 } }

        before { expect_any_instance_of(RouteCompletionService).to receive(:after_create_user_on_resource) }

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

  describe 'set_completed_notification' do
    let(:subject) { completor.send(:set_completed_notification!, criteria) }
    let(:criteria) { { action: :show, instance: :neighborhood, instance_id: instance_id } }
    let(:instance_id) { inapp_notification.instance_id}

    context 'no inapp_notification on user' do
      let(:anyone) { FactoryBot.create(:pro_user) }
      let!(:inapp_notification) { create(:inapp_notification, user: anyone) }

      it { expect(subject).to eq(0) }
      it { expect(subject && inapp_notification.reload.completed_at).to be(nil) }
    end

    context 'some inapp_notification on user' do
      let!(:inapp_notification) { create(:inapp_notification, user: user) }

      it { expect(subject).to eq(1) }
      it { expect(subject && inapp_notification.reload.completed_at).to be_a(ActiveSupport::TimeWithZone) }
    end

    context 'wrong instance_id' do
      let!(:inapp_notification) { create(:inapp_notification, user: user) }
      let(:instance_id) { inapp_notification.instance_id + 1 }

      it { expect(subject).to eq(0) }
      it { expect(subject && inapp_notification.reload.completed_at).to be(nil) }
    end

    context 'empty instance_id is valid for all' do
      let!(:inapp_notification) { create(:inapp_notification, user: user) }
      let(:criteria) { { action: :show, instance: :neighborhood } }

      it { expect(subject).to eq(1) }
      it { expect(subject && inapp_notification.reload.completed_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end

  describe 'set_completed_recommandation' do
    let(:subject) { completor.send(:set_completed_recommandation!, criteria) }

    context 'no user_recommandation on user' do
      let(:anyone) { FactoryBot.create(:pro_user) }
      let!(:user_recommandation) { create(:user_recommandation, user: anyone, instance: :resource, action: :index) }

      let(:criteria) { { instance: :resource, action: :index } }

      it { expect(subject).to eq(0) }
      it { expect(subject && user_recommandation.reload.completed_at).to be(nil) }
    end

    context 'some user_recommandation on user' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :resource, action: :index) }

      let(:criteria) { { instance: :resource, action: :index } }

      it { expect(subject).to eq(1) }
      it { expect(subject && user_recommandation.reload.completed_at).to be_a(ActiveSupport::TimeWithZone) }
    end

    context 'wrong criteria on action' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :resource, action: :create) }

      let(:criteria) { { instance: :resource, action: :index } }

      it { expect(subject).to eq(0) }
      it { expect(subject && user_recommandation.reload.completed_at).to be(nil) }
    end

    context 'wrong criteria on instance' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :neighborhood, action: :index) }

      let(:criteria) { { instance: :resource, action: :index } }

      it { expect(subject).to eq(0) }
      it { expect(subject && user_recommandation.reload.completed_at).to be(nil) }
    end
  end

  describe 'log_completed_recommandation' do
    let(:subject) { completor.send(:log_completed_recommandation!, criteria) }
    let(:criteria) { { instance: :resource, action: :index } }

    context 'no existing user_recommandation' do
      it { expect(subject).to eq(true) }
      it { expect { subject }.to change { UserRecommandation.count }.by(1) }
    end

    context 'no existing completed user_recommandation' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :resource, action: :index) }

      it { expect(subject).to eq(true) }
      it { expect { subject }.to change { UserRecommandation.count }.by(1) }
    end

    context 'existing completed user_recommandation' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :resource, action: :index, completed_at: Time.now) }

      it { expect(subject).to eq(nil) }
      it { expect { subject }.not_to change { UserRecommandation.count } }
    end

    context 'existing skipped user_recommandation' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :resource, action: :index, skipped_at: Time.now) }

      it { expect(subject).to eq(nil) }
      it { expect { subject }.not_to change { UserRecommandation.count } }
    end

    context 'no existing action user_recommandation' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :resource, action: :create) }

      it { expect(subject).to eq(true) }
      it { expect { subject }.to change { UserRecommandation.count }.by(1) }
    end

    context 'no existing instance user_recommandation' do
      let!(:user_recommandation) { create(:user_recommandation, user: user, instance: :outing, action: :index) }

      it { expect(subject).to eq(true) }
      it { expect { subject }.to change { UserRecommandation.count }.by(1) }
    end
  end
end
