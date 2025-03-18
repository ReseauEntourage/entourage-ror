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
      instance_mapping.each_with_object({}) do |(rails_field, salesforce_field), hash|
        hash[salesforce_field] = mapping.send(rails_field)
      end
    end

    # table structure
    def fields
      self.class.fields(table_name)
    end

    def field_values field
      self.class.field_values(table_name, field)
    end

    def field_has_value? field, value
      self.class.field_has_value?(table_name, field, value)
    end

    def tracked_fields_with_types
      self.class.tracked_fields_with_types(table_name)
    end

    def has_cdc?
      self.class.has_cdc?(table_name)
    end

    class << self
      def client
        SalesforceServices::Connect.client
      end

      # table operation
      def create_field table_name, field_name, field_label, field_type
        field_payload = {
          "FullName" => "#{table_name}.#{field_name}",
          "Metadata" => {
            "fullName" => "#{table_name}.#{field_name}",
            "label" => field_label,
            "type" => field_type
          }
        }

        return unless client.post(CREATE_ENDPOINT, field_payload.to_json, 'Content-Type' => 'application/json').success?

        set_visibility_for_table_field(table_name, field_name)
      end

      def delete_field table_name, field_name
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

      # describe table field values
      def field_values table_name, field
        fields(table_name).find { |f| f[:name] == field }[:picklistValues]
      end

      # check whether a field includes a value
      # example: field_has_value?("Campaign", "Type_evenement__c", SalesforceServices::Outing::TYPE_EVENEMENT)
      def field_has_value? table_name, field, value
        field_values(table_name, field).any? do |config|
          config["value"] == value
        end
      end

      # check whether table has fields with history tracking (flows)
      def tracked_fields_with_types table_name
        client.query(%(
          SELECT DeveloperName, DataType FROM FieldDefinition
          WHERE EntityDefinition.QualifiedApiName = '#{table_name}'
          AND IsFieldHistoryTracked = true
        )).map { |field| { name: field.DeveloperName, type: field.DataType }}
      end

      def has_cdc? table_name
        client.get("/services/data/v57.0/sobjects/#{table_name}ChangeEvent/describe")

        true
      rescue Restforce::NotFoundError
        false
      end
    end
  end
end

