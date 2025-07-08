module SalesforceServices
  class CampaignMember
    class << self
      STATUSES = [
        {
          label: "No Show",
          api_name: "No_Show",
          sort_order: 3,
          has_responded: false,
          is_default: false
        },
        {
          label: "Inscrit",
          api_name: "Inscrit",
          sort_order: 4,
          has_responded: true,
          is_default: false
        },
        {
          label: "Participé",
          api_name: "Participe",
          sort_order: 5,
          has_responded: true,
          is_default: false
        },
        {
          label: "A annulé",
          api_name: "A annulé",
          sort_order: 6,
          has_responded: true,
          is_default: false
        }
      ]

      def client
        SalesforceServices::Connect.client
      end

      # Méthode pour créer des statuts de membre de campagne
      def create_campaign_member_status(campaign_id, label, sort_order = 1, has_responded = false, is_default = false)
        begin
          result = client.create!(
            'CampaignMemberStatus',
            CampaignId: campaign_id,
            Label: label,
            # SortOrder: sort_order,
            HasResponded: has_responded,
            IsDefault: is_default
          )

          result
        rescue Restforce::ResponseError => e
          return get_existing_status(campaign_id, label) if e.message.include?('DUPLICATE_VALUE')
        rescue => e
          nil
        end
      end

      # Méthode pour récupérer un statut existant
      def get_existing_status(campaign_id, label)
        begin
          result = client.query("SELECT Id, Label, SortOrder, HasResponded, IsDefault FROM CampaignMemberStatus WHERE CampaignId = '#{campaign_id}' AND Label = '#{label}' LIMIT 1")
          result.first
        rescue => e
          puts "Erreur lors de la récupération du statut existant : #{e.message}"
          nil
        end
      end

      # Méthode pour créer ou récupérer un statut (upsert-like behavior)
      def create_or_get_campaign_member_status(campaign_id, label, sort_order = 1, has_responded = false, is_default = false)
        # Vérifier d'abord si le statut existe
        existing_status = get_existing_status(campaign_id, label)

        if existing_status
          puts "Statut existant trouvé : #{existing_status.Label}"
          return existing_status
        end

        # Créer si n'existe pas
        create_campaign_member_status(campaign_id, label, sort_order, has_responded, is_default)
      end

      def create_multiple_campaign_member_statuses(campaign_id, statuses_config)
        created_statuses = []

        statuses_config.each do |status_config|
          status = create_campaign_member_status(
            campaign_id,
            status_config[:label],
            status_config[:sort_order] || 1,
            status_config[:has_responded] || false,
            status_config[:is_default] || false
          )

          created_statuses << status if status
        end

        created_statuses
      end

      # Méthode pour récupérer les statuts existants d'une campagne
      def get_campaign_member_statuses(campaign_id)
        begin
          client.query("SELECT Id, Label, SortOrder, HasResponded, IsDefault FROM CampaignMemberStatus WHERE CampaignId = '#{campaign_id}' ORDER BY SortOrder")
        rescue => e
          puts "Erreur lors de la récupération des statuts : #{e.message}"
          []
        end
      end

      # Méthode pour supprimer un statut (attention : peut impacter les données existantes)
      def delete_campaign_member_status(status_id)
        begin
          result = client.destroy!('CampaignMemberStatus', status_id)
          puts "Statut supprimé : #{status_id}"
          result
        rescue => e
          puts "Erreur lors de la suppression : #{e.message}"
          false
        end
      end

      # Méthode pour mettre à jour un statut existant
      def update_campaign_member_status(status_id, updates)
        begin
          result = client.update!('CampaignMemberStatus', status_id, updates)
          puts "Statut mis à jour : #{status_id}"
          result
        rescue => e
          puts "Erreur lors de la mise à jour : #{e.message}"
          false
        end
      end

      # Méthode de configuration des statuts
      def setup_campaign_statuses(campaign_id)
        create_multiple_campaign_member_statuses(campaign_id, STATUSES)
      end

      # Méthode pour vérifier si un statut existe déjà
      def campaign_member_status_exists?(campaign_id, label)
        begin
          result = client.query("SELECT Id FROM CampaignMemberStatus WHERE CampaignId = '#{campaign_id}' AND Label = '#{label}'")
          result.size > 0
        rescue => e
          puts "Erreur lors de la vérification : #{e.message}"
          false
        end
      end

      # Méthode pour créer un statut seulement s'il n'existe pas
      def create_campaign_member_status_if_not_exists(campaign_id, label, sort_order = 1, has_responded = false, is_default = false)
        return nil if campaign_member_status_exists?(campaign_id, label)

        create_campaign_member_status(campaign_id, label, sort_order, has_responded, is_default)
      end
    end
  end
end
