class SmsDelivery < ActiveRecord::Base
    validates_presence_of :phone_number, :status, :sms_type, :provider
end
