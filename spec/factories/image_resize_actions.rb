FactoryBot.define do
  factory :image_resize_action do
    bucket { ENV['ENTOURAGE_IMAGES_BUCKET'] }
    path { 'destination/path' }
    destination_path { 'destination/medium/path' }
    destination_size { :medium }
    status { :OK }
  end
end
