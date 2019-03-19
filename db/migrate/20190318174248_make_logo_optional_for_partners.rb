class MakeLogoOptionalForPartners < ActiveRecord::Migration
  def change
    change_column_null :partners, :large_logo_url, true
    change_column_null :partners, :small_logo_url, true
  end
end
