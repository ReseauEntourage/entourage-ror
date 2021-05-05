class SmsDelivery < ApplicationRecord
    validates_presence_of :phone_number, :status, :sms_type, :provider
end
