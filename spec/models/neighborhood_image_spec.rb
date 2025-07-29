require 'rails_helper'

RSpec.describe NeighborhoodImage, type: :model do
  describe 'size image_url_medium_or_default' do
    let(:image_resize_action) { create :image_resize_action, destination_path: 'bar' }
    let(:neighborhood_image) { create :neighborhood_image, image_url: 'foo', image_url_medium: image_resize_action }

    subject { neighborhood_image.image_url_medium_or_default }

    context 'with image_resize_action' do
      it { expect(subject).to eq('bar') }
    end

    context 'without image_resize_action' do
      let(:image_resize_action) { nil }

      it { expect(subject).to eq('foo') }
    end
  end
end
