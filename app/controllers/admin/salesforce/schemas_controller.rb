module Admin
  module Salesforce
    class SchemasController < Admin::BaseController
      def show_user
        @interface = SalesforceServices::UserTableInterface.new(instance: nil)
      end

      def show_outing
        @interface = SalesforceServices::OutingTableInterface.new(instance: nil)
      end

      def show_lead
        @interface = SalesforceServices::LeadTableInterface.new(instance: nil)
      end

      def show_contact
        @interface = SalesforceServices::ContactTableInterface.new(instance: nil)
      end
    end
  end
end
