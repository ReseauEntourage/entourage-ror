require 'rails_helper'

describe ImageResizeAction do
  describe '.find_path_for' do
    let(:bucket) { 'images-bucket' }

    let!(:resized) { create :image_resize_action, bucket: bucket, path: 'resized.jpg', destination_path: 'medium/resized.jpg', destination_size: :medium }

    def queries_on_image_resize_actions
      queries = []
      callback = lambda { |*, payload| queries << payload[:sql] if payload[:sql] =~ /image_resize_actions/ }

      result = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }

      [result, queries.size]
    end

    after { ActiveSupport::CurrentAttributes.reset_all }

    it 'returns the resized path' do
      expect(ImageResizeAction.find_path_for(bucket: bucket, path: 'resized.jpg', size: :medium)).to eq('medium/resized.jpg')
    end

    it 'returns the original path when the image has not been resized' do
      expect(ImageResizeAction.find_path_for(bucket: bucket, path: 'original.jpg', size: :medium)).to eq('original.jpg')
    end

    it 'returns the original path for the default size, without query' do
      result, count = queries_on_image_resize_actions do
        ImageResizeAction.find_path_for(bucket: bucket, path: 'resized.jpg', size: :default)
      end

      expect(result).to eq('resized.jpg')
      expect(count).to eq(0)
    end

    context 'after preload_paths' do
      before { ImageResizeAction.preload_paths(bucket: bucket, paths: ['resized.jpg', 'original.jpg', nil], size: :medium) }

      it 'serves resized and not resized images without query' do
        result, count = queries_on_image_resize_actions do
          [
            ImageResizeAction.find_path_for(bucket: bucket, path: 'resized.jpg', size: :medium),
            ImageResizeAction.find_path_for(bucket: bucket, path: 'original.jpg', size: 'medium')
          ]
        end

        expect(result).to eq(['medium/resized.jpg', 'original.jpg'])
        expect(count).to eq(0)
      end

      it 'still queries the paths, sizes and buckets that were not preloaded' do
        result, count = queries_on_image_resize_actions do
          [
            ImageResizeAction.find_path_for(bucket: bucket, path: 'other.jpg', size: :medium),
            ImageResizeAction.find_path_for(bucket: bucket, path: 'resized.jpg', size: :small),
            ImageResizeAction.find_path_for(bucket: 'other-bucket', path: 'resized.jpg', size: :medium)
          ]
        end

        expect(result).to eq(['other.jpg', 'resized.jpg', 'resized.jpg'])
        expect(count).to eq(3)
      end

      it 'is forgotten when the request state is reset' do
        ActiveSupport::CurrentAttributes.reset_all

        _, count = queries_on_image_resize_actions do
          ImageResizeAction.find_path_for(bucket: bucket, path: 'resized.jpg', size: :medium)
        end

        expect(count).to eq(1)
      end
    end

    it 'preloads in a single query' do
      _, count = queries_on_image_resize_actions do
        ImageResizeAction.preload_paths(bucket: bucket, paths: ['resized.jpg', 'a.jpg', 'b.jpg'], size: :medium)
      end

      expect(count).to eq(1)
    end
  end
end
