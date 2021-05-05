class AddTourReportCcToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :tour_report_cc, :text
  end
end
