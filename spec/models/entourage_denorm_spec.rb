require 'rails_helper'

RSpec.describe EntourageDenorm, type: :model do
  describe 'after_create update entourage' do
    let(:entourage) { create :entourage }
    let(:chat_message) { create :chat_message, messageable: entourage, image_url: image_url }
    let(:image_url) { nil }

    let(:subject) { EntourageDenorm.find_by(entourage_id: chat_message.messageable_id) }

    describe 'set max_chat_message_created_at' do
      it do
        expect(subject).to be_kind_of EntourageDenorm
        expect(subject.max_chat_message_created_at).to be_kind_of Time
        expect(subject.max_chat_message_created_at.change(usec: 0)).to eq(chat_message.created_at.change(usec: 0))
      end
    end

    describe 'set has_image_url' do
      context 'as false' do
        let(:image_url) { nil }

        it do
          expect(subject).to be_kind_of EntourageDenorm
          expect(subject.has_image_url).to be(false)
        end
      end

      context 'as true' do
        let(:image_url) { 'https://foo.bar.png' }

        it do
          expect(subject).to be_kind_of EntourageDenorm
          expect(subject.has_image_url).to be(true)
        end
      end
    end
  end
end
