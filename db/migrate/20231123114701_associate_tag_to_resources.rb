class AssociateTagToResources < ActiveRecord::Migration[6.1]
  def change
    if EnvironmentHelper.production?
      Resource.find_by_id(37).tap { |resource| resource ? resource.update_attribute(:tag, :neighborhood) : nil }
      Resource.find_by_id(15).tap { |resource| resource ? resource.update_attribute(:tag, :outing) : nil }
      Resource.find_by_id(34).tap { |resource| resource ? resource.update_attribute(:tag, :action) : nil }
    end
  end
end
