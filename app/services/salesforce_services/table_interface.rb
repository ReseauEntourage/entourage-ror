module SalesforceServices
  class TableInterface
    CREATE_ENDPOINT = "/services/data/v55.0/tooling/sobjects/CustomField/"
    DELETE_ENDPOINT = "/services/data/v55.0/tooling/sobjects/CustomField/%s.%s"
    PERMISSION_ENDPOINT = "/services/data/v55.0/sobjects/FieldPermissions/"

    attr_accessor :table_name, :instance

    def initialize table_name:, instance:
      @table_name = table_name
      @instance = instance
    end

    # mapping
    def external_id_key
      raise NotImplementedError
    end

    def external_id_value
      raise NotImplementedError
    end

    def mapping
      raise NotImplementedError
    end

    def instance_mapping
      raise NotImplementedError
    end

    def sf_fields
      instance_mapping.values
    end

    def mapped_fields
      @mapped_fields ||= instance_mapping.each_with_object({}) do |(rails_field, salesforce_field), hash|
        hash[salesforce_field] = mapping.send(rails_field)
      end
    end

    # table structure
    def fields
      @fields ||= self.class.fields(table_name)
    end

    def field_values field
      self.class.field_values(table_name, field)
    end

    def field_has_value? field, value
      self.class.field_has_value?(table_name, field, value)
    end

    def record_url record_id
      self.class.record_url(table_name, record_id)
    end

    def records fields: [], per: 50, page: 1
      fields = instance_mapping.values unless fields.any?

      self.class.records(table_name, fields: fields, per: per, page: page)
    end

    class << self
      def client
        SalesforceServices::Connect.client
      end

      # table operation
      def create_field table_name, field_name, field_label, field_type, default_value: nil, required: false
        return if field_exists?(table_name, field_name)

        field_payload = {
          "FullName" => "#{table_name}.#{field_name}__c",
          "Metadata" => {
            "fullName" => "#{table_name}.#{field_name}__c",
            "label" => field_label,
            "type" => field_type,
            "required" => required
          }.compact
        }

        if field_type.downcase == 'number'
          field_payload["Metadata"]["precision"] = 18
          field_payload["Metadata"]["scale"] = 0
        end

        return unless client.post(CREATE_ENDPOINT, field_payload.to_json, 'Content-Type' => 'application/json').success?

        set_visibility_for_table_field(table_name, field_name)
      end

      def delete_field table_name, field_name
        return unless field_exists?(table_name, field_name)

        client.delete(DELETE_ENDPOINT % [table_name, field_name]).success?
      end

      def set_visibility_for_table_field table_name, field_name
        permission_sets.each do |perm_set|
          permission_payload = {
            "ParentId" => perm_set["Id"],
            "SObjectType" => table_name,
            "Field" => "#{table_name}.#{field_name}",
            "PermissionsRead" => true,
            "PermissionsEdit" => true
          }

          client.post(PERMISSION_ENDPOINT, permission_payload.to_json, 'Content-Type' => 'application/json')
        end
      end

      def permission_sets
        client.query("SELECT Id, ProfileId FROM PermissionSet WHERE IsOwnedByProfile = true")
      end

      # describe table fields
      def fields table_name
        Rails.cache.fetch("salesforce_table_fields_#{table_name}", expires_in: 12.hours) do
          metadata = client.describe(table_name)
          return [] unless metadata && metadata[:fields]

          metadata[:fields].map do |field|
            {
              name: field[:name],
              type: field[:type],
              label: field[:label],
              required: field[:nillable] == false
            }
          end.sort_by { |field| [field[:required] ? 0 : 1, field[:name]] }
        end
      end

      def field table_name, field_name
        fields(table_name).find { |f| f[:name] == field_name }
      end

      def field_exists? table_name, field_name
        field(table_name, field_name).present?
      end

      # describe table field values
      def field_values table_name, field_name
        field(table_name, field_name)[:picklistValues]
      end

      # check whether a field includes a value
      # example: field_has_value?("Campaign", "Type_evenement__c", SalesforceServices::Outing::TYPE_EVENEMENT)
      def field_has_value? table_name, field_name, value
        field_values(table_name, field_name).any? do |config|
          config["value"] == value
        end
      end

      def record_url table_name, record_id
        "#{ENV['SALESFORCE_LOGIN_URL']}/lightning/r/#{table_name}/#{record_id}/view"
      end

      def records table_name, fields: ["Id"], per: 500, page: 1
        {
          data: client.query(build_query(table_name, fields, per, page)).map(&:to_h),
          total: count_records(table_name)
        }
      end

      def count_records table_name
        client.query(build_query(table_name, ["COUNT()"])).size
      end

      def where_clause
      end

      def order_clause
      end

      private

      def build_query table_name, fields, per = nil, page = nil
        query = "SELECT #{fields.join(', ')} FROM #{table_name}"
        query += " WHERE #{where_clause}" if where_clause.present?
        query += " ORDER BY #{order_clause}" if order_clause.present? if per && page
        query += " LIMIT #{per} OFFSET #{(page - 1) * per}" if per && page
        query
      end
    end
  end
end

