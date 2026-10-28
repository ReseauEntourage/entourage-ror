require 'rails_helper'

describe UserServices::CreatedContent do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood) { FactoryBot.create(:neighborhood, participants: [user]) }

  subject { described_class.new(user, messageable_type: 'Neighborhood').get }

  it 'includes posts created by the user' do
    post = FactoryBot.create(:chat_message, messageable: neighborhood, user: user, content: 'hello')

    item = subject.find { |i| i[:message] == post }
    expect(item[:kind]).to eq(:post)
    expect(item[:group]).to eq(neighborhood)
    expect(item[:extrait]).to eq('hello')
  end

  it 'includes comments created by the user, distinguished from posts' do
    post = FactoryBot.create(:chat_message, messageable: neighborhood, content: 'a post')
    comment = FactoryBot.create(:chat_message, messageable: neighborhood, user: user, content: 'a comment', parent: post)

    item = subject.find { |i| i[:message] == comment }
    expect(item[:kind]).to eq(:comment)
  end

  it 'excludes content from other users' do
    other_user = FactoryBot.create(:public_user)
    FactoryBot.create(:chat_message, messageable: neighborhood, user: other_user)

    expect(subject).to be_empty
  end

  it 'labels the status of a deleted message' do
    deleter = FactoryBot.create(:admin_user)
    post = FactoryBot.create(:chat_message, messageable: neighborhood, user: user)
    ChatServices::Deleter.new(user: deleter, chat_message: post).delete(true)

    item = subject.find { |i| i[:message] == post }
    expect(item[:status_label]).to eq('Supprimé')
  end

  it 'still includes content from a neighborhood that has since been deactivated' do
    FactoryBot.create(:chat_message, messageable: neighborhood, user: user)
    neighborhood.update_column(:status, 'deleted')

    expect(subject).not_to be_empty
  end
end
