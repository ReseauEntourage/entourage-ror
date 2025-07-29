class DropOldTables < ActiveRecord::Migration[6.1]
  def up
    drop_table :old_answers
    drop_table :old_atd_synchronizations
    drop_table :old_atd_users
    drop_table :old_encounters
    drop_table :old_entourage_displays
    drop_table :old_organizations
    drop_table :old_questions
    drop_table :old_registration_requests
    drop_table :old_simplified_tour_points
    drop_table :old_tour_areas
    drop_table :old_tour_points
    drop_table :old_tours
  end

  def down
    create_table 'old_answers', id: :integer, default: -> { "nextval('answers_id_seq'::regclass)" }, force: :cascade do |t|
      t.integer 'question_id', null: false
      t.integer 'encounter_id', null: false
      t.string 'value', null: false
      t.index ['encounter_id', 'question_id'], name: 'index_answers_on_encounter_id_and_question_id'
    end
  
    create_table 'old_atd_synchronizations', id: :serial, force: :cascade do |t|
      t.string 'filename', null: false
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
      t.index ['filename'], name: 'index_old_atd_synchronizations_on_filename', unique: true
    end
  
    create_table 'old_atd_users', id: :serial, force: :cascade do |t|
      t.integer 'user_id'
      t.integer 'atd_id', null: false
      t.string 'tel_hash'
      t.string 'mail_hash'
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
      t.index ['atd_id', 'user_id'], name: 'index_old_atd_users_on_atd_id_and_user_id', unique: true
    end
  
    create_table 'old_encounters', id: :integer, default: -> { "nextval('encounters_id_seq'::regclass)" }, force: :cascade do |t|
      t.datetime 'date', precision: nil
      t.integer 'user_id'
      t.datetime 'created_at', precision: nil
      t.datetime 'updated_at', precision: nil
      t.string 'street_person_name'
      t.float 'latitude'
      t.float 'longitude'
      t.string 'voice_message_url'
      t.integer 'tour_id'
      t.string 'encrypted_message'
      t.string 'address'
      t.index ['tour_id'], name: 'index_encounters_on_tour_id'
    end
  
    create_table 'old_entourage_displays', id: :integer, default: -> { "nextval('entourage_displays_id_seq'::regclass)" }, force: :cascade do |t|
      t.integer 'entourage_id'
      t.float 'distance'
      t.integer 'feed_rank'
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
      t.string 'source', default: 'newsfeed'
      t.integer 'user_id', null: false
      t.index ['entourage_id'], name: 'index_entourage_displays_on_entourage_id'
    end
  
    create_table 'old_organizations', id: :integer, default: -> { "nextval('organizations_id_seq'::regclass)" }, force: :cascade do |t|
      t.string 'name'
      t.string 'description'
      t.string 'phone'
      t.string 'address'
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
      t.string 'logo_url'
      t.string 'local_entity'
      t.string 'email'
      t.string 'website_url'
      t.boolean 'test_organization', default: false, null: false
      t.text 'tour_report_cc'
      t.index ['name'], name: 'index_organizations_on_name', unique: true
    end
  
    create_table 'old_questions', id: :integer, default: -> { "nextval('questions_id_seq'::regclass)" }, force: :cascade do |t|
      t.string 'title', null: false
      t.string 'answer_type', null: false
      t.integer 'organization_id', null: false
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
      t.index ['organization_id'], name: 'index_questions_on_organization_id'
    end
  
    create_table 'old_registration_requests', id: :integer, default: -> { "nextval('registration_requests_id_seq'::regclass)" }, force: :cascade do |t|
      t.string 'status', default: 'pending', null: false
      t.string 'extra', null: false
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
    end
  
    create_table 'old_simplified_tour_points', id: :integer, default: -> { "nextval('simplified_tour_points_id_seq'::regclass)" }, force: :cascade do |t|
      t.float 'latitude', null: false
      t.float 'longitude', null: false
      t.integer 'tour_id', null: false
      t.datetime 'created_at', precision: nil
      t.index ['latitude', 'longitude', 'tour_id'], name: 'index_simplified_tour_points_on_coordinates_and_tour_id'
      t.index ['tour_id'], name: 'index_simplified_tour_points_on_tour_id'
    end
  
    create_table 'old_tour_areas', id: :integer, default: -> { "nextval('tour_areas_id_seq'::regclass)" }, force: :cascade do |t|
      t.string 'departement', limit: 5
      t.string 'area', null: false
      t.string 'status', default: 'inactive', null: false
      t.string 'email', null: false
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
      t.index ['area'], name: 'index_tour_areas_on_area'
      t.index ['status'], name: 'index_tour_areas_on_status'
    end
  
    create_table 'old_tour_points', id: :integer, default: -> { "nextval('tour_points_id_seq'::regclass)" }, force: :cascade do |t|
      t.float 'latitude', null: false
      t.float 'longitude', null: false
      t.integer 'tour_id', null: false
      t.datetime 'passing_time', precision: nil, null: false
      t.datetime 'created_at', precision: nil
      t.datetime 'updated_at', precision: nil
      t.index ['tour_id', 'created_at'], name: 'index_tour_points_on_tour_id_and_created_at'
      t.index ['tour_id', 'id'], name: 'index_tour_points_on_tour_id_and_id'
      t.index ['tour_id', 'latitude', 'longitude'], name: 'index_tour_points_on_tour_id_and_latitude_and_longitude'
    end
  
    create_table 'old_tours', id: :integer, default: -> { "nextval('tours_id_seq'::regclass)" }, force: :cascade do |t|
      t.string 'tour_type'
      t.datetime 'created_at', precision: nil
      t.datetime 'updated_at', precision: nil
      t.integer 'status'
      t.integer 'vehicle_type', default: 0
      t.integer 'user_id'
      t.datetime 'closed_at', precision: nil
      t.integer 'length', default: 0
      t.integer 'encounters_count', default: 0, null: false
      t.integer 'number_of_people', default: 0, null: false
      t.float 'latitude'
      t.float 'longitude'
      t.index 'st_setsrid(st_makepoint(longitude, latitude), 4326)', name: 'index_tours_on_coordinates', using: :gist
      t.index ['latitude', 'longitude'], name: 'index_tours_on_latitude_and_longitude'
      t.index ['user_id', 'updated_at', 'tour_type'], name: 'index_tours_on_user_id_and_updated_at_and_tour_type'
    end
  end
end

