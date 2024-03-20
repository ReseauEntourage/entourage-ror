# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 202401111415004) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "unaccent"

  create_table "active_admin_comments", id: :serial, force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.string "place_name", null: false
    t.string "street_address"
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.string "postal_code", limit: 8
    t.string "country", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_place_id"
    t.integer "user_id", null: false
    t.integer "position", default: 1, null: false
    t.string "city"
    t.index ["user_id", "position"], name: "index_addresses_on_user_id_and_position", unique: true
  end

  create_table "announcements", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "body"
    t.string "image_url"
    t.string "action"
    t.string "url"
    t.string "icon"
    t.boolean "webview"
    t.integer "position"
    t.string "status", default: "draft", null: false
    t.jsonb "areas", default: [], null: false
    t.jsonb "user_goals", default: [], null: false
    t.string "category"
    t.string "image_portrait_url"
    t.string "image_url_copy"
    t.string "image_portrait_url_copy"
    t.string "webapp_url"
    t.index ["areas"], name: "index_announcements_on_areas", using: :gin
    t.index ["category"], name: "index_announcements_on_category"
    t.index ["image_portrait_url"], name: "index_announcements_on_image_portrait_url"
    t.index ["user_goals"], name: "index_announcements_on_user_goals", using: :gin
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
  end

  create_table "categories_pois", id: false, force: :cascade do |t|
    t.integer "poi_id"
    t.integer "category_id"
    t.index ["category_id"], name: "index_categories_pois_on_category_id"
    t.index ["poi_id"], name: "index_categories_pois_on_poi_id"
  end

  create_table "chat_messages", id: :serial, force: :cascade do |t|
    t.integer "messageable_id", null: false
    t.string "messageable_type", null: false
    t.text "content"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "message_type", limit: 20, default: "text", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "ancestry"
    t.string "image_url"
    t.string "status", default: "active"
    t.integer "deleter_id"
    t.datetime "deleted_at"
    t.string "uuid_v2", limit: 12, null: false
    t.integer "survey_id"
    t.integer "comments_count", default: 0
    t.index "((metadata -> 'conversation_message_broadcast_id'::text))", name: "chat_messages_conversation_message_broadcast_id", using: :hash
    t.index ["ancestry"], name: "index_chat_messages_on_ancestry"
    t.index ["content"], name: "index_chat_messages_on_content", opclass: :gin_trgm_ops, using: :gin
    t.index ["created_at"], name: "index_chat_messages_on_created_at"
    t.index ["message_type"], name: "index_chat_messages_on_message_type"
    t.index ["messageable_id", "messageable_type"], name: "index_chat_messages_on_messageable_id_and_messageable_type"
    t.index ["status"], name: "index_chat_messages_on_status"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "contact_subscriptions", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.string "profile"
    t.string "subject"
    t.string "message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_contact_subscriptions_on_email", unique: true
  end

  create_table "conversation_message_broadcasts", id: :serial, force: :cascade do |t|
    t.string "area_old"
    t.text "content", null: false
    t.string "goal"
    t.string "title", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "draft", null: false
    t.datetime "sent_at"
    t.integer "sent_recipients_count"
    t.string "area_type"
    t.jsonb "areas", default: []
    t.string "conversation_type", default: "Entourage"
    t.json "conversation_ids", default: {}
    t.index ["area_old"], name: "index_conversation_message_broadcasts_on_area_old"
    t.index ["area_type"], name: "index_conversation_message_broadcasts_on_area_type"
    t.index ["conversation_type"], name: "index_conversation_message_broadcasts_on_conversation_type"
    t.index ["goal"], name: "index_conversation_message_broadcasts_on_goal"
    t.index ["status"], name: "index_conversation_message_broadcasts_on_status"
  end

  create_table "coordination", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
  end

  create_table "denorm_daily_engagements", force: :cascade do |t|
    t.date "date", null: false
    t.integer "user_id", null: false
    t.string "postal_code"
    t.index ["date", "user_id", "postal_code"], name: "unicity_denorm_daily_engagements_on_date_user_id_postal_code", unique: true
  end

  create_table "digest_emails", id: :serial, force: :cascade do |t|
    t.datetime "deliver_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "status", null: false
    t.datetime "status_changed_at", null: false
  end

  create_table "donations", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "amount", null: false
    t.string "donation_type", null: false
    t.string "reference", null: false
    t.string "channel"
    t.jsonb "protected_attributes", default: [], null: false
    t.boolean "first_time_donator", default: false, null: false
    t.integer "app_user_id"
    t.string "sex"
    t.string "country"
    t.string "postal_code"
    t.string "city"
    t.string "payment_frequency"
    t.string "payment_type"
    t.date "donator_birthdate"
    t.integer "iraiser_donator_id"
    t.date "donator_iraiser_account_creation_date"
    t.date "donation_once_last_date"
    t.date "donation_regular_first_date"
    t.date "donator_donation_regular_last_date"
    t.integer "donator_donation_regular_last_year_total"
    t.integer "donator_donation_regular_amount"
    t.index ["date"], name: "index_donations_on_date"
    t.index ["iraiser_donator_id"], name: "index_donations_on_iraiser_donator_id"
    t.index ["postal_code"], name: "index_donations_on_postal_code"
  end

  create_table "email_campaigns", id: :serial, force: :cascade do |t|
    t.string "name", limit: 40, null: false
    t.index ["name"], name: "index_email_campaigns_on_name", unique: true
  end

  create_table "email_categories", id: :serial, force: :cascade do |t|
    t.string "name", limit: 30, null: false
    t.string "description", limit: 100, null: false
    t.index ["name"], name: "index_email_categories_on_name", unique: true
  end

  create_table "email_deliveries", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "sent_at", null: false
    t.integer "email_campaign_id", null: false
    t.index ["user_id", "email_campaign_id"], name: "index_email_deliveries_on_user_id_and_email_campaign_id"
  end

  create_table "email_preferences", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "email_category_id", null: false
    t.boolean "subscribed", null: false
    t.datetime "subscription_changed_at", null: false
    t.index ["user_id", "email_category_id"], name: "index_email_preferences_on_user_id_and_email_category_id", unique: true
  end

  create_table "entourage_denorms", id: :serial, force: :cascade do |t|
    t.integer "entourage_id", null: false
    t.datetime "max_chat_message_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "has_image_url", default: false
    t.index ["entourage_id"], name: "index_entourage_denorms_on_entourage_id"
  end

  create_table "entourage_images", force: :cascade do |t|
    t.string "title"
    t.string "landscape_url"
    t.string "portrait_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "landscape_thumbnail_url"
    t.string "portrait_thumbnail_url"
  end

  create_table "entourage_invitations", id: :serial, force: :cascade do |t|
    t.integer "invitable_id", null: false
    t.string "invitable_type_old"
    t.integer "inviter_id", null: false
    t.integer "invitee_id"
    t.string "invitation_mode", null: false
    t.string "phone_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "metadata", default: {}, null: false
    t.index ["invitable_id"], name: "index_entourage_invitations_on_invitable_id"
    t.index ["invitee_id"], name: "index_entourage_invitations_on_invitee_id"
    t.index ["inviter_id", "phone_number", "invitable_id"], name: "unique_invitation_by_entourage", unique: true
    t.index ["inviter_id"], name: "index_entourage_invitations_on_inviter_id"
    t.index ["phone_number"], name: "index_entourage_invitations_on_phone_number"
  end

  create_table "entourage_moderations", id: :serial, force: :cascade do |t|
    t.integer "entourage_id", null: false
    t.boolean "moderated", default: false, null: false
    t.string "action_author_type"
    t.string "action_recipient_type"
    t.string "action_type"
    t.string "action_recipient_consent_obtained"
    t.date "moderated_at"
    t.string "moderation_contact_channel"
    t.string "legacy_moderator"
    t.string "moderation_action"
    t.text "moderation_comment"
    t.date "action_outcome_reported_at"
    t.string "action_outcome"
    t.string "action_success_reason"
    t.string "action_failure_reason"
    t.string "action_target_type"
    t.integer "moderator_id"
    t.index ["entourage_id"], name: "index_entourage_moderations_on_entourage_id", unique: true
    t.index ["moderator_id"], name: "index_entourage_moderations_on_moderator_id"
  end

  create_table "entourage_scores", id: :serial, force: :cascade do |t|
    t.integer "entourage_id", null: false
    t.integer "user_id", null: false
    t.float "base_score", null: false
    t.float "final_score", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entourage_id"], name: "index_entourage_scores_on_entourage_id"
  end

  create_table "entourages", id: :serial, force: :cascade do |t|
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.string "entourage_type", null: false
    t.integer "user_id", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.integer "number_of_people", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.uuid "uuid"
    t.string "category"
    t.boolean "use_suggestions", default: false, null: false
    t.string "display_category"
    t.string "uuid_v2", limit: 71, null: false
    t.string "postal_code", limit: 8
    t.string "country", limit: 2
    t.string "community", limit: 9, null: false
    t.string "group_type", limit: 14, null: false
    t.jsonb "metadata", default: {}, null: false
    t.boolean "public", default: false
    t.datetime "feed_updated_at"
    t.string "image_url"
    t.boolean "online", default: false
    t.string "event_url"
    t.boolean "admin_pin", default: false, null: false
    t.boolean "pin", default: false
    t.jsonb "pins", default: [], null: false
    t.string "display_category_copy"
    t.string "other_interest"
    t.string "recurrency_identifier"
    t.datetime "status_changed_at"
    t.datetime "notification_sent_at"
    t.datetime "working_hours_sent_at"
    t.integer "number_of_confirmed_people", default: 0
    t.index "st_setsrid(st_makepoint(longitude, latitude), 4326)", name: "index_entourages_on_coordinates", using: :gist
    t.index ["community", "group_type"], name: "index_entourages_on_community_and_group_type"
    t.index ["country", "postal_code"], name: "index_entourages_on_country_and_postal_code"
    t.index ["created_at"], name: "index_entourages_on_created_at"
    t.index ["latitude", "longitude"], name: "index_entourages_on_latitude_and_longitude"
    t.index ["pin"], name: "index_entourages_on_pin"
    t.index ["user_id"], name: "index_entourages_on_user_id"
    t.index ["uuid"], name: "index_entourages_on_uuid", unique: true
    t.index ["uuid_v2"], name: "index_entourages_on_uuid_v2", unique: true
  end

  create_table "entourages_users", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "entourage_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_message_read"
    t.index ["user_id", "entourage_id"], name: "index_entourages_users_on_user_id_and_entourage_id", unique: true
  end

# Could not dump table "events" because of following StandardError
#   Unknown type 'event_name' for column 'name'

  create_table "experimental_pending_request_reminders", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_experimental_pending_request_reminders_on_user_id"
  end

  create_table "followings", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "partner_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["partner_id"], name: "index_followings_on_partner_id"
    t.index ["user_id", "partner_id"], name: "index_followings_on_user_id_and_partner_id", unique: true
  end

  create_table "image_resize_actions", force: :cascade do |t|
    t.string "bucket", null: false
    t.string "path", null: false
    t.string "destination_path", null: false
    t.string "destination_size", default: "medium", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bucket", "path"], name: "index_image_resize_actions_on_bucket_and_path"
  end

  create_table "inapp_notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "instance"
    t.integer "instance_id"
    t.datetime "completed_at"
    t.datetime "skipped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "context"
    t.string "content"
    t.datetime "displayed_at"
    t.integer "post_id"
    t.integer "sender_id"
    t.string "title"
    t.index ["displayed_at"], name: "index_inapp_notifications_on_displayed_at"
    t.index ["user_id"], name: "index_inapp_notifications_on_user_id"
  end

  create_table "join_requests", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "joinable_id", null: false
    t.string "joinable_type", null: false
    t.string "status", default: "pending", null: false
    t.text "message"
    t.datetime "last_message_read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "distance"
    t.string "role", limit: 11, null: false
    t.datetime "requested_at"
    t.datetime "accepted_at"
    t.datetime "email_notification_sent_at"
    t.datetime "archived_at"
    t.string "report_prompt_status"
    t.datetime "confirmed_at"
    t.index ["confirmed_at"], name: "index_join_requests_on_confirmed_at"
    t.index ["joinable_type", "joinable_id", "status"], name: "index_join_requests_on_joinable_type_and_joinable_id_and_status"
    t.index ["user_id", "joinable_id", "joinable_type", "status"], name: "index_user_joinable_on_join_requests"
    t.index ["user_id", "joinable_id", "joinable_type"], name: "index_join_requests_on_user_id_and_joinable_id"
  end

  create_table "login_histories", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "connected_at", null: false
    t.index "date_trunc('hour'::text, connected_at), user_id", name: "index_login_histories_on_connected_at_by_hour", unique: true
  end

  create_table "marketing_referers", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "email"
  end

  create_table "moderation_areas", id: :serial, force: :cascade do |t|
    t.string "departement", limit: 2, null: false
    t.string "name", null: false
    t.integer "moderator_id"
    t.string "slack_channel", limit: 80
    t.text "welcome_message_1_offer_help"
    t.text "welcome_message_2_offer_help"
    t.text "welcome_message_1_ask_for_help"
    t.text "welcome_message_2_ask_for_help"
    t.text "welcome_message_1_organization"
    t.text "welcome_message_2_organization"
    t.text "welcome_message_1_goal_not_known"
    t.text "welcome_message_2_goal_not_known"
    t.string "slack_moderator_id_old"
    t.boolean "activity", default: false, null: false
    t.integer "animator_id"
    t.integer "mobilisator_id"
    t.integer "sourcing_id"
    t.integer "accompanyist_id"
    t.integer "community_builder_id"
    t.index ["departement"], name: "index_moderation_areas_on_departement", unique: true
  end

  create_table "moderator_reads", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "moderatable_id", null: false
    t.string "moderatable_type", null: false
    t.datetime "read_at", null: false
    t.index ["user_id", "moderatable_id", "moderatable_type"], name: "index_moderator_reads_on_user_id_and_moderatable"
  end

  create_table "neighborhood_images", force: :cascade do |t|
    t.string "title"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "neighborhoods", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", limit: 256
    t.string "description"
    t.string "ethics"
    t.string "image_url"
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "feed_updated_at"
    t.string "welcome_message"
    t.string "other_interest"
    t.string "google_place_id"
    t.string "place_name"
    t.string "postal_code"
    t.string "street_address"
    t.string "status", default: "active", null: false
    t.datetime "status_changed_at"
    t.integer "number_of_people", default: 0
    t.boolean "is_departement", default: false
    t.string "zone"
    t.boolean "public", default: true
    t.string "uuid_v2", limit: 12, null: false
    t.string "country", default: "FR"
    t.index "st_setsrid(st_makepoint(longitude, latitude), 4326)", name: "index_neighborhoods_on_coordinates", using: :gist
    t.index ["feed_updated_at"], name: "index_neighborhoods_on_feed_updated_at"
    t.index ["name"], name: "index_neighborhoods_on_name"
    t.index ["postal_code"], name: "index_neighborhoods_on_postal_code"
    t.index ["status"], name: "index_neighborhoods_on_status"
    t.index ["user_id"], name: "index_neighborhoods_on_user_id"
    t.index ["uuid_v2"], name: "index_neighborhoods_on_uuid_v2", unique: true
    t.index ["zone"], name: "index_neighborhoods_on_zone"
  end

  create_table "neighborhoods_entourages", force: :cascade do |t|
    t.bigint "neighborhood_id"
    t.bigint "entourage_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entourage_id"], name: "index_neighborhoods_entourages_on_entourage_id"
    t.index ["neighborhood_id"], name: "index_neighborhoods_entourages_on_neighborhood_id"
  end

  create_table "newsletter_subscriptions", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255
    t.boolean "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "zone"
    t.string "status"
    t.index ["email"], name: "index_newsletter_subscriptions_on_email"
  end

  create_table "notification_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.jsonb "permissions", default: {}, null: false
    t.index ["user_id"], name: "index_notification_permissions_on_user_id"
  end

  create_table "old_answers", id: :integer, default: -> { "nextval('answers_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "question_id", null: false
    t.integer "encounter_id", null: false
    t.string "value", null: false
    t.index ["encounter_id", "question_id"], name: "index_answers_on_encounter_id_and_question_id"
  end

  create_table "old_atd_synchronizations", id: :serial, force: :cascade do |t|
    t.string "filename", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filename"], name: "index_old_atd_synchronizations_on_filename", unique: true
  end

  create_table "old_atd_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "atd_id", null: false
    t.string "tel_hash"
    t.string "mail_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["atd_id", "user_id"], name: "index_old_atd_users_on_atd_id_and_user_id", unique: true
  end

  create_table "old_encounters", id: :integer, default: -> { "nextval('encounters_id_seq'::regclass)" }, force: :cascade do |t|
    t.datetime "date"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "street_person_name"
    t.float "latitude"
    t.float "longitude"
    t.string "voice_message_url"
    t.integer "tour_id"
    t.string "encrypted_message"
    t.string "address"
    t.index ["tour_id"], name: "index_encounters_on_tour_id"
  end

  create_table "old_organizations", id: :integer, default: -> { "nextval('organizations_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "phone"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logo_url"
    t.string "local_entity"
    t.string "email"
    t.string "website_url"
    t.boolean "test_organization", default: false, null: false
    t.text "tour_report_cc"
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "old_questions", id: :integer, default: -> { "nextval('questions_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "title", null: false
    t.string "answer_type", null: false
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_questions_on_organization_id"
  end

  create_table "old_registration_requests", id: :integer, default: -> { "nextval('registration_requests_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.string "extra", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "old_simplified_tour_points", id: :integer, default: -> { "nextval('simplified_tour_points_id_seq'::regclass)" }, force: :cascade do |t|
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.integer "tour_id", null: false
    t.datetime "created_at"
    t.index ["latitude", "longitude", "tour_id"], name: "index_simplified_tour_points_on_coordinates_and_tour_id"
    t.index ["tour_id"], name: "index_simplified_tour_points_on_tour_id"
  end

  create_table "old_tour_areas", id: :integer, default: -> { "nextval('tour_areas_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "departement", limit: 5
    t.string "area", null: false
    t.string "status", default: "inactive", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area"], name: "index_tour_areas_on_area"
    t.index ["status"], name: "index_tour_areas_on_status"
  end

  create_table "old_tour_points", id: :integer, default: -> { "nextval('tour_points_id_seq'::regclass)" }, force: :cascade do |t|
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.integer "tour_id", null: false
    t.datetime "passing_time", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["tour_id", "created_at"], name: "index_tour_points_on_tour_id_and_created_at"
    t.index ["tour_id", "id"], name: "index_tour_points_on_tour_id_and_id"
    t.index ["tour_id", "latitude", "longitude"], name: "index_tour_points_on_tour_id_and_latitude_and_longitude"
  end

  create_table "old_tours", id: :integer, default: -> { "nextval('tours_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "tour_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "status"
    t.integer "vehicle_type", default: 0
    t.integer "user_id"
    t.datetime "closed_at"
    t.integer "length", default: 0
    t.integer "encounters_count", default: 0, null: false
    t.integer "number_of_people", default: 0, null: false
    t.float "latitude"
    t.float "longitude"
    t.index "st_setsrid(st_makepoint(longitude, latitude), 4326)", name: "index_tours_on_coordinates", using: :gist
    t.index ["latitude", "longitude"], name: "index_tours_on_latitude_and_longitude"
    t.index ["user_id", "updated_at", "tour_type"], name: "index_tours_on_user_id_and_updated_at_and_tour_type"
  end

  create_table "options", force: :cascade do |t|
    t.string "key", null: false
    t.string "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_options_on_key"
  end

  create_table "outing_recurrences", force: :cascade do |t|
    t.string "identifier"
    t.integer "recurrency"
    t.boolean "continue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_outing_recurrences_on_identifier", unique: true
  end

  create_table "partner_invitations", id: :serial, force: :cascade do |t|
    t.integer "partner_id", null: false
    t.integer "inviter_id", null: false
    t.string "invitee_email", null: false
    t.string "invitee_name"
    t.string "invitee_role_title"
    t.integer "invitee_id"
    t.string "token", null: false
    t.datetime "invited_at", null: false
    t.datetime "accepted_at"
    t.datetime "deleted_at"
    t.string "status", null: false
    t.index ["partner_id", "invitee_email"], name: "index_pending_partner_invitations_on_partner_and_invitee_email", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["partner_id", "invitee_id"], name: "index_accepted_partner_invitations_on_partner_and_invitee_id", unique: true, where: "((status)::text = 'accepted'::text)"
    t.index ["token"], name: "index_partner_invitations_on_token", unique: true
  end

  create_table "partner_join_requests", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "partner_id"
    t.string "postal_code"
    t.string "new_partner_name"
    t.string "partner_role_title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_partner_join_requests_on_user_id"
  end

  create_table "partners", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "large_logo_url"
    t.string "small_logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "phone"
    t.string "address"
    t.string "website_url"
    t.string "email"
    t.text "volunteers_needs"
    t.text "donations_needs"
    t.string "postal_code", limit: 8
    t.float "latitude"
    t.float "longitude"
    t.boolean "staff", default: false, null: false
  end

  create_table "pois", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "adress", limit: 255
    t.string "phone", limit: 255
    t.string "website"
    t.string "email", limit: 255
    t.string "audience"
    t.integer "category_id"
    t.boolean "validated", default: false, null: false
    t.integer "partner_id"
    t.tsvector "textsearch"
    t.integer "source", default: 0
    t.integer "source_id", default: 0
    t.string "hours"
    t.string "languages"
    t.string "postal_code"
    t.index ["category_id", "latitude", "longitude"], name: "index_pois_on_category_id_and_latitude_and_longitude", where: "validated"
    t.index ["latitude", "longitude"], name: "index_pois_on_latitude_and_longitude"
    t.index ["partner_id"], name: "index_pois_on_partner_id", unique: true
    t.index ["postal_code"], name: "index_pois_on_postal_code"
    t.index ["source_id"], name: "index_pois_on_source_id"
    t.index ["textsearch"], name: "index_pois_on_textsearch", using: :gin
  end

  create_table "reactions", force: :cascade do |t|
    t.string "name"
    t.string "key"
    t.string "image_url"
    t.integer "position", default: 0
  end

  create_table "recommandation_images", force: :cascade do |t|
    t.string "title"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recommandations", force: :cascade do |t|
    t.string "name", limit: 256
    t.string "image_url"
    t.string "instance", null: false
    t.string "action", default: "show", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "user_goals", default: [], null: false
    t.string "status", default: "active", null: false
    t.integer "position_offer_help"
    t.integer "position_ask_for_help"
    t.integer "fragment", default: 0
    t.string "description"
    t.string "argument_value"
    t.index ["action"], name: "index_recommandations_on_action"
    t.index ["instance"], name: "index_recommandations_on_instance"
    t.index ["name"], name: "index_recommandations_on_name"
    t.index ["status", "position_ask_for_help", "fragment"], name: "index_recommandations_on_status_and_position_ask_for_help", where: "(((status)::text = 'active'::text) AND (position_ask_for_help IS NOT NULL))"
    t.index ["status", "position_offer_help", "fragment"], name: "index_recommandations_on_status_and_position_offer_for_help", where: "(((status)::text = 'active'::text) AND (position_offer_help IS NOT NULL))"
    t.index ["user_goals"], name: "index_recommandations_on_user_goals", using: :gin
  end

  create_table "resource_images", force: :cascade do |t|
    t.string "title"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resources", force: :cascade do |t|
    t.string "name", limit: 256, null: false
    t.string "category", limit: 32, default: "all", null: false
    t.string "description"
    t.string "image_url"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration"
    t.boolean "is_video", default: false
    t.string "status", default: "active", null: false
    t.string "uuid_v2", limit: 12, null: false
    t.string "tag"
    t.index ["name"], name: "index_resources_on_name"
    t.index ["tag"], name: "index_resources_on_tag"
    t.index ["uuid_v2"], name: "index_resources_on_uuid_v2", unique: true
  end

  create_table "rpush_apps", force: :cascade do |t|
    t.string "name", null: false
    t.string "environment"
    t.text "certificate"
    t.string "password"
    t.integer "connections", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.string "auth_key"
    t.string "client_id"
    t.string "client_secret"
    t.string "access_token"
    t.datetime "access_token_expiration"
    t.text "apn_key"
    t.string "apn_key_id"
    t.string "team_id"
    t.string "bundle_id"
    t.boolean "feedback_enabled", default: true
  end

  create_table "rpush_feedback", force: :cascade do |t|
    t.string "device_token"
    t.datetime "failed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "app_id"
    t.index ["device_token"], name: "index_rpush_feedback_on_device_token"
  end

  create_table "rpush_notifications", force: :cascade do |t|
    t.integer "badge"
    t.string "device_token"
    t.string "sound"
    t.text "alert"
    t.text "data"
    t.integer "expiry", default: 86400
    t.boolean "delivered", default: false, null: false
    t.datetime "delivered_at"
    t.boolean "failed", default: false, null: false
    t.datetime "failed_at"
    t.integer "error_code"
    t.text "error_description"
    t.datetime "deliver_after"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "alert_is_json", default: false, null: false
    t.string "type", null: false
    t.string "collapse_key"
    t.boolean "delay_while_idle", default: false, null: false
    t.text "registration_ids"
    t.integer "app_id", null: false
    t.integer "retries", default: 0
    t.string "uri"
    t.datetime "fail_after"
    t.boolean "processing", default: false, null: false
    t.integer "priority"
    t.text "url_args"
    t.string "category"
    t.boolean "content_available", default: false, null: false
    t.text "notification"
    t.boolean "mutable_content", default: false, null: false
    t.string "external_device_id"
    t.string "thread_id"
    t.boolean "dry_run", default: false, null: false
    t.boolean "sound_is_json", default: false
    t.index ["delivered", "failed", "processing", "deliver_after", "created_at"], name: "index_rpush_notifications_multi", where: "((NOT delivered) AND (NOT failed))"
  end

  create_table "salesforce_configs", force: :cascade do |t|
    t.string "klass", null: false
    t.string "developer_name"
    t.string "salesforce_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["salesforce_id"], name: "index_salesforce_configs_on_salesforce_id"
  end

  create_table "sensitive_words", id: :serial, force: :cascade do |t|
    t.string "raw", null: false
    t.string "pattern", null: false
    t.string "match_type", default: "stem", null: false
    t.string "scope", default: "all", null: false
    t.string "category"
    t.index ["pattern"], name: "index_sensitive_words_on_pattern", unique: true
  end

  create_table "sensitive_words_checks", id: :serial, force: :cascade do |t|
    t.string "status", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.text "matches", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_sensitive_words_checks_on_record_type_and_record_id", unique: true
  end

  create_table "session_histories", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "date", null: false
    t.string "platform", limit: 7, null: false
    t.string "notifications_permissions", limit: 14
    t.index ["user_id", "platform", "date"], name: "index_session_histories_on_user_id_and_platform_and_date", unique: true
  end

# Could not dump table "sms_deliveries" because of following StandardError
#   Unknown type 'sms_delivery_status' for column 'status'

  create_table "store_daily_reports", id: :serial, force: :cascade do |t|
    t.string "store_id"
    t.string "app_name"
    t.date "report_date"
    t.integer "nb_downloads"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_date", "app_name", "store_id"], name: "index_store_daily_reports_date_store_app", unique: true
  end

  create_table "survey_responses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "chat_message_id", null: false
    t.jsonb "responses", default: []
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["chat_message_id"], name: "index_survey_responses_on_chat_message_id"
    t.index ["user_id"], name: "index_survey_responses_on_user_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.jsonb "choices", default: []
    t.boolean "multiple", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "summary", default: []
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tours_users", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "tour_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_message_read"
    t.index ["user_id", "tour_id"], name: "index_tours_users_on_user_id_and_tour_id", unique: true
  end

  create_table "translations", force: :cascade do |t|
    t.integer "instance_id", null: false
    t.string "instance_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "fr", default: {}, null: false
    t.jsonb "en", default: {}, null: false
    t.jsonb "de", default: {}, null: false
    t.jsonb "pl", default: {}, null: false
    t.jsonb "ro", default: {}, null: false
    t.jsonb "uk", default: {}, null: false
    t.jsonb "ar", default: {}, null: false
    t.string "from_lang", default: "fr", null: false
    t.jsonb "es", default: {}, null: false
    t.index ["instance_id", "instance_type"], name: "index_translations_on_instance_id_and_instance_type"
  end

  create_table "user_applications", id: :serial, force: :cascade do |t|
    t.string "push_token", null: false
    t.string "device_os", null: false
    t.string "version", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "device_family"
    t.string "notifications_permissions"
    t.index ["push_token"], name: "index_user_applications_on_push_token", unique: true
    t.index ["user_id", "device_family"], name: "index_user_applications_on_user_id_and_device_family"
  end

  create_table "user_blocked_users", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "blocked_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_user_id"], name: "index_user_blocked_users_on_blocked_user_id"
    t.index ["user_id", "blocked_user_id"], name: "index_user_blocked_users_on_user_id_and_blocked_user_id", unique: true
    t.index ["user_id"], name: "index_user_blocked_users_on_user_id"
  end

  create_table "user_denorms", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "last_created_action_id"
    t.integer "last_join_request_id"
    t.integer "last_private_chat_message_id"
    t.integer "last_group_chat_message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_created_action_id"], name: "index_user_denorms_on_last_created_action_id"
    t.index ["last_group_chat_message_id"], name: "index_user_denorms_on_last_group_chat_message_id"
    t.index ["last_join_request_id"], name: "index_user_denorms_on_last_join_request_id"
    t.index ["last_private_chat_message_id"], name: "index_user_denorms_on_last_private_chat_message_id"
    t.index ["user_id"], name: "index_user_denorms_on_user_id"
  end

  create_table "user_histories", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "updater_id"
    t.string "kind", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_user_histories_on_kind"
    t.index ["updater_id"], name: "index_user_histories_on_updater_id"
    t.index ["user_id"], name: "index_user_histories_on_user_id"
  end

  create_table "user_moderations", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "expectations"
    t.string "acquisition_channel"
    t.string "content_sent"
    t.string "skills"
    t.boolean "accepts_event_invitations"
    t.boolean "accepts_volunteering_offers"
    t.boolean "ambassador"
    t.index ["user_id"], name: "index_user_moderations_on_user_id", unique: true
  end

  create_table "user_phone_changes", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "admin_id"
    t.string "kind", null: false
    t.string "phone_was", null: false
    t.string "phone", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_user_phone_changes_on_admin_id"
    t.index ["kind"], name: "index_user_phone_changes_on_kind"
    t.index ["user_id"], name: "index_user_phone_changes_on_user_id"
  end

  create_table "user_reactions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "reaction_id", null: false
    t.integer "instance_id", null: false
    t.string "instance_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["instance_id", "instance_type"], name: "index_user_reactions_on_instance_id_and_instance_type"
    t.index ["reaction_id"], name: "index_user_reactions_on_reaction_id"
  end

  create_table "user_recommandations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "recommandation_id"
    t.datetime "completed_at"
    t.datetime "congrats_at"
    t.datetime "skipped_at"
    t.string "name"
    t.string "image_url"
    t.string "action", null: false
    t.string "instance", null: false
    t.integer "instance_id"
    t.string "instance_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fragment"
    t.index ["completed_at", "skipped_at"], name: "index_user_recommandations_on_completed_at_and_skipped_at"
    t.index ["instance"], name: "index_user_recommandations_on_instance"
    t.index ["user_id", "recommandation_id"], name: "index_user_recommandations_on_user_id_and_recommandation_id", unique: true, where: "((completed_at IS NULL) AND (skipped_at IS NULL))"
    t.index ["user_id"], name: "index_user_recommandations_on_user_id"
  end

  create_table "user_relationships", id: :serial, force: :cascade do |t|
    t.integer "source_user_id", null: false
    t.integer "target_user_id", null: false
    t.string "relation_type", null: false
    t.index ["source_user_id", "target_user_id", "relation_type"], name: "unique_user_relationship", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "phone", null: false
    t.string "token"
    t.string "device_id"
    t.integer "device_type"
    t.string "sms_code"
    t.integer "organization_id"
    t.boolean "manager", default: false, null: false
    t.float "default_latitude"
    t.float "default_longitude"
    t.boolean "admin", default: false, null: false
    t.string "user_type", default: "pro", null: false
    t.string "avatar_key"
    t.string "validation_status", default: "validated", null: false
    t.boolean "deleted", default: false, null: false
    t.integer "marketing_referer_id", default: 1, null: false
    t.datetime "last_sign_in_at"
    t.boolean "old_atd_friend", default: false, null: false
    t.boolean "use_suggestions", default: false, null: false
    t.string "about", limit: 200
    t.string "community", limit: 9, null: false
    t.string "encrypted_password"
    t.jsonb "roles", default: [], null: false
    t.datetime "first_sign_in_at"
    t.datetime "onboarding_sequence_start_at"
    t.integer "address_id"
    t.boolean "accepts_emails_deprecated", default: true, null: false
    t.datetime "last_email_sent_at"
    t.string "targeting_profile"
    t.integer "partner_id"
    t.boolean "partner_admin", default: false, null: false
    t.string "partner_role_title"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "goal"
    t.jsonb "interests_old", default: [], null: false
    t.string "encrypted_admin_password"
    t.string "reset_admin_password_token"
    t.datetime "reset_admin_password_sent_at"
    t.boolean "super_admin", default: false
    t.datetime "unblock_at"
    t.integer "travel_distance", default: 40
    t.string "birthday", limit: 5
    t.string "other_interest"
    t.json "options", default: {}
    t.string "lang", default: "fr"
    t.string "slack_id"
    t.string "salesforce_id"
    t.index ["address_id"], name: "index_users_on_address_id"
    t.index ["email"], name: "index_users_on_email"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["partner_id"], name: "index_users_on_partner_id"
    t.index ["phone", "community"], name: "index_users_on_phone_and_community", unique: true
    t.index ["roles"], name: "index_users_on_roles", using: :gin
    t.index ["token"], name: "index_users_on_token", unique: true
    t.index ["unblock_at"], name: "index_users_on_unblock_at"
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  create_table "users_resources", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "resource_id"
    t.boolean "watched", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_id"], name: "index_users_resources_on_resource_id"
    t.index ["user_id", "resource_id"], name: "index_users_resources_on_user_id_and_resource_id", unique: true
    t.index ["user_id"], name: "index_users_resources_on_user_id"
  end

  add_foreign_key "experimental_pending_request_reminders", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "users", "addresses"
end
