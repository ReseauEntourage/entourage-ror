class Organization < ActiveRecord::Base
  validates_presence_of [:name, :description, :phone, :address]
  validates_uniqueness_of [:name]
  has_many :users
  has_many :questions

  scope :not_test, -> { where test_organization: false}
  scope :ordered, -> { order("name ASC")}

  def active_members_last_month
    users.where('last_sign_in_at > ?', Time.current - 30.days).count
  end

  def last_tour_date
    begin
      Tour.joins(user: :organization).where(users: {organization_id: id}).order('created_at DESC')
      .first
      .created_at
      .strftime('%d/%m/%Y')
    rescue
      "Pas encore de mauraude."
    end
  end

  def tours_count
    Tour.joins(user: :organization)
      .where(users: {organization_id: id})
      .count
  end

  def meetings_count
    Encounter.joins(tour: :user)
      .where(users: {organization_id: id})
      .count
  end
end
