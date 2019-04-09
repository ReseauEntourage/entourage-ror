module Api
  module V1
    class ContactsController < Api::V1::BaseController
      def update
        return render file: 'mocks/contacts.json'
      end
    end
  end
end
