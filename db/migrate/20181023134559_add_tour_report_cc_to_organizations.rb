class AddTourReportCcToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :tour_report_cc, :text
  end
end
