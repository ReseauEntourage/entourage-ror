module V1
  module Users
    class PhoneOnlySerializer < ActiveModel::Serializer
      attributes :phone
    end
  end
end
