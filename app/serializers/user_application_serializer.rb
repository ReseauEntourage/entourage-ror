class UserApplicationSerializer < ActiveModel::Serializer
  attributes :id, :push_token, :device_os, :version, :user_id
end
