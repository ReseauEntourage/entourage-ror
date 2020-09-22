# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20200924130803) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "postgis"

  create_table "TEST_events_20181112_copy", id: false, force: :cascade do |t|
    t.string  "event_date",                    limit: 65535
    t.integer "event_timestamp",               limit: 8
    t.string  "event_name",                    limit: 65535
    t.string  "event_params",                  limit: 65535
    t.integer "event_previous_timestamp",      limit: 8
    t.float   "event_value_in_usd"
    t.integer "event_bundle_sequence_id",      limit: 8
    t.integer "event_server_timestamp_offset", limit: 8
    t.string  "user_id",                       limit: 65535
    t.string  "user_pseudo_id",                limit: 65535
    t.string  "user_properties",               limit: 65535
    t.integer "user_first_touch_timestamp",    limit: 8
    t.string  "user_ltv",                      limit: 65535
    t.string  "device",                        limit: 65535
    t.string  "geo",                           limit: 65535
    t.string  "app_info",                      limit: 65535
    t.string  "traffic_source",                limit: 65535
    t.string  "stream_id",                     limit: 65535
    t.string  "platform",                      limit: 65535
    t.string  "event_dimensions",              limit: 65535
  end

  create_table "TEST_users_prepared", id: false, force: :cascade do |t|
    t.integer  "id",                           limit: 8
    t.text     "created_at"
    t.datetime "created_at_parsed"
    t.integer  "created_at_parsed_year",       limit: 8
    t.integer  "created_at_parsed_month",      limit: 8
    t.integer  "created_at_parsed_day",        limit: 8
    t.integer  "since_created_at_parsed_days", limit: 8
    t.text     "updated_at"
    t.string   "email",                        limit: 255
    t.text     "email_localpart"
    t.text     "email_domain"
    t.string   "first_name",                   limit: 255
    t.string   "last_name",                    limit: 255
    t.text     "phone"
    t.string   "token",                        limit: 255
    t.text     "device_id"
    t.integer  "device_type",                  limit: 8
    t.text     "sms_code"
    t.integer  "organization_id",              limit: 8
    t.boolean  "manager"
    t.float    "default_latitude"
    t.float    "default_longitude"
    t.boolean  "admin"
    t.text     "user_type"
    t.text     "avatar_key"
    t.text     "validation_status"
    t.boolean  "deleted"
    t.integer  "marketing_referer_id",         limit: 8
    t.text     "last_sign_in_at"
    t.boolean  "atd_friend"
    t.boolean  "use_suggestions"
    t.string   "about",                        limit: 200
    t.string   "community",                    limit: 9
    t.text     "encrypted_password"
    t.text     "roles"
    t.text     "first_sign_in_at"
    t.text     "onboarding_sequence_start_at"
    t.integer  "address_id",                   limit: 8
    t.boolean  "accepts_emails_deprecated"
    t.text     "last_email_sent_at"
    t.text     "targeting_profile"
    t.text     "partner_id"
    t.boolean  "partner_admin"
    t.text     "partner_role_title"
  end

  create_table "TEST_users_prepared_by_device_type", id: false, force: :cascade do |t|
    t.integer "device_type",         limit: 8
    t.integer "organization_id_min", limit: 8
    t.boolean "manager_min"
    t.float   "use_suggestions_avg"
    t.integer "count",               limit: 8
  end

  create_table "active_admin_comments", id: false, force: :cascade do |t|
    t.integer  "id",                        default: "nextval('active_admin_comments_id_seq'::regclass)", null: false
    t.string   "namespace",     limit: 255
    t.text     "body"
    t.string   "resource_id",   limit: 255,                                                               null: false
    t.string   "resource_type", limit: 255,                                                               null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "addresses", force: :cascade do |t|
    t.string   "place_name",                            null: false
    t.string   "street_address"
    t.float    "latitude",                              null: false
    t.float    "longitude",                             null: false
    t.string   "postal_code",     limit: 8
    t.string   "country",         limit: 2
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "google_place_id"
    t.integer  "user_id",                               null: false
    t.integer  "position",                  default: 1, null: false
  end

  add_index "addresses", ["user_id", "position"], name: "index_addresses_on_user_id_and_position", unique: true, using: :btree

  create_table "announcements", force: :cascade do |t|
    t.string  "title"
    t.string  "body"
    t.string  "image_url"
    t.string  "action"
    t.string  "url"
    t.string  "icon"
    t.boolean "webview"
    t.integer "position"
    t.string  "status",     default: "draft", null: false
    t.jsonb   "areas",      default: [],      null: false
    t.jsonb   "user_goals", default: [],      null: false
  end

  add_index "announcements", ["areas"], name: "index_announcements_on_areas", using: :gin
  add_index "announcements", ["user_goals"], name: "index_announcements_on_user_goals", using: :gin

  create_table "answers", force: :cascade do |t|
    t.integer "question_id",  null: false
    t.integer "encounter_id", null: false
    t.string  "value",        null: false
  end

  add_index "answers", ["encounter_id", "question_id"], name: "index_answers_on_encounter_id_and_question_id", using: :btree

  create_table "atd_synchronizations", force: :cascade do |t|
    t.string   "filename",   null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "atd_synchronizations", ["filename"], name: "index_atd_synchronizations_on_filename", unique: true, using: :btree

  create_table "atd_users", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "atd_id",     null: false
    t.string   "tel_hash"
    t.string   "mail_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "atd_users", ["atd_id", "user_id"], name: "index_atd_users_on_atd_id_and_user_id", unique: true, using: :btree

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
  end

  create_table "categories_pois", id: false, force: :cascade do |t|
    t.integer "poi_id"
    t.integer "category_id"
  end

  add_index "categories_pois", ["category_id"], name: "index_categories_pois_on_category_id", using: :btree
  add_index "categories_pois", ["poi_id"], name: "index_categories_pois_on_poi_id", using: :btree

  create_table "chat_messages", force: :cascade do |t|
    t.integer  "messageable_id",                               null: false
    t.string   "messageable_type",                             null: false
    t.text     "content",                                      null: false
    t.integer  "user_id",                                      null: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "message_type",     limit: 20, default: "text", null: false
    t.jsonb    "metadata",                    default: {},     null: false
  end

  add_index "chat_messages", ["created_at"], name: "index_chat_messages_on_created_at", using: :btree
  add_index "chat_messages", ["messageable_id", "messageable_type"], name: "index_chat_messages_on_messageable_id_and_messageable_type", using: :btree
  add_index "chat_messages", ["user_id"], name: "index_chat_messages_on_user_id", using: :btree

  create_table "coordination", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
  end

  create_table "digest_emails", force: :cascade do |t|
    t.datetime "deliver_at",                     null: false
    t.jsonb    "data",              default: {}, null: false
    t.string   "status",                         null: false
    t.datetime "status_changed_at",              null: false
  end

  create_table "donations", force: :cascade do |t|
    t.date    "date",                                 null: false
    t.integer "amount",                               null: false
    t.string  "donation_type",                        null: false
    t.string  "reference",                            null: false
    t.string  "channel"
    t.jsonb   "protected_attributes", default: [],    null: false
    t.boolean "first_time_donator",   default: false, null: false
    t.integer "app_user_id"
  end

  create_table "email_campaigns", force: :cascade do |t|
    t.string "name", limit: 40, null: false
  end

  add_index "email_campaigns", ["name"], name: "index_email_campaigns_on_name", unique: true, using: :btree

  create_table "email_categories", force: :cascade do |t|
    t.string "name",        limit: 30,  null: false
    t.string "description", limit: 100, null: false
  end

  add_index "email_categories", ["name"], name: "index_email_categories_on_name", unique: true, using: :btree

  create_table "email_deliveries", force: :cascade do |t|
    t.integer  "user_id",           null: false
    t.datetime "sent_at",           null: false
    t.integer  "email_campaign_id", null: false
  end

  add_index "email_deliveries", ["user_id", "email_campaign_id"], name: "index_email_deliveries_on_user_id_and_email_campaign_id", using: :btree

  create_table "email_preferences", force: :cascade do |t|
    t.integer  "user_id",                 null: false
    t.integer  "email_category_id",       null: false
    t.boolean  "subscribed",              null: false
    t.datetime "subscription_changed_at", null: false
  end

  add_index "email_preferences", ["user_id", "email_category_id"], name: "index_email_preferences_on_user_id_and_email_category_id", unique: true, using: :btree

  create_table "encounters", force: :cascade do |t|
    t.datetime "date"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "street_person_name", limit: 255
    t.float    "latitude"
    t.float    "longitude"
    t.string   "voice_message_url",  limit: 255
    t.integer  "tour_id"
    t.string   "encrypted_message"
    t.string   "address"
  end

  add_index "encounters", ["tour_id"], name: "index_encounters_on_tour_id", using: :btree

  create_table "entourage_displays", force: :cascade do |t|
    t.integer  "entourage_id"
    t.float    "distance"
    t.integer  "feed_rank"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "source",       default: "newsfeed"
    t.integer  "user_id",                           null: false
  end

  add_index "entourage_displays", ["entourage_id"], name: "index_entourage_displays_on_entourage_id", using: :btree

  create_table "entourage_invitations", force: :cascade do |t|
    t.integer  "invitable_id",                        null: false
    t.string   "invitable_type",                      null: false
    t.integer  "inviter_id",                          null: false
    t.integer  "invitee_id"
    t.string   "invitation_mode",                     null: false
    t.string   "phone_number",                        null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "status",          default: "pending", null: false
    t.jsonb    "metadata",        default: {},        null: false
  end

  add_index "entourage_invitations", ["invitable_id", "invitable_type"], name: "index_entourage_invitations_on_invitable_id_and_invitable_type", using: :btree
  add_index "entourage_invitations", ["invitee_id"], name: "index_entourage_invitations_on_invitee_id", using: :btree
  add_index "entourage_invitations", ["inviter_id", "phone_number", "invitable_id", "invitable_type"], name: "unique_invitation_by_entourage", unique: true, using: :btree
  add_index "entourage_invitations", ["inviter_id"], name: "index_entourage_invitations_on_inviter_id", using: :btree
  add_index "entourage_invitations", ["phone_number"], name: "index_entourage_invitations_on_phone_number", using: :btree

  create_table "entourage_moderations", force: :cascade do |t|
    t.integer "entourage_id",                                      null: false
    t.boolean "moderated",                         default: false, null: false
    t.string  "action_author_type"
    t.string  "action_recipient_type"
    t.string  "action_type"
    t.string  "action_recipient_consent_obtained"
    t.date    "moderated_at"
    t.string  "moderation_contact_channel"
    t.string  "legacy_moderator"
    t.string  "moderation_action"
    t.text    "moderation_comment"
    t.date    "action_outcome_reported_at"
    t.string  "action_outcome"
    t.string  "action_success_reason"
    t.string  "action_failure_reason"
    t.string  "action_target_type"
    t.integer "moderator_id"
  end

  add_index "entourage_moderations", ["entourage_id"], name: "index_entourage_moderations_on_entourage_id", unique: true, using: :btree
  add_index "entourage_moderations", ["moderator_id"], name: "index_entourage_moderations_on_moderator_id", using: :btree

  create_table "entourage_scores", force: :cascade do |t|
    t.integer  "entourage_id", null: false
    t.integer  "user_id",      null: false
    t.float    "base_score",   null: false
    t.float    "final_score",  null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "entourage_scores", ["entourage_id"], name: "index_entourage_scores_on_entourage_id", using: :btree

  create_table "entourages", force: :cascade do |t|
    t.string   "status",                      default: "open", null: false
    t.string   "title",                                        null: false
    t.string   "entourage_type",                               null: false
    t.integer  "user_id",                                      null: false
    t.float    "latitude",                                     null: false
    t.float    "longitude",                                    null: false
    t.integer  "number_of_people",            default: 0,      null: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "description"
    t.uuid     "uuid"
    t.string   "category"
    t.boolean  "use_suggestions",             default: false,  null: false
    t.string   "display_category"
    t.string   "uuid_v2",          limit: 71,                  null: false
    t.string   "postal_code",      limit: 8
    t.string   "country",          limit: 2
    t.string   "community",        limit: 9,                   null: false
    t.string   "group_type",       limit: 14,                  null: false
    t.jsonb    "metadata",                    default: {},     null: false
    t.boolean  "public",                      default: false
    t.datetime "feed_updated_at"
  end

  add_index "entourages", ["country", "postal_code"], name: "index_entourages_on_country_and_postal_code", using: :btree
  add_index "entourages", ["latitude", "longitude"], name: "index_entourages_on_latitude_and_longitude", using: :btree
  add_index "entourages", ["user_id"], name: "index_entourages_on_user_id", using: :btree
  add_index "entourages", ["uuid"], name: "index_entourages_on_uuid", unique: true, using: :btree
  add_index "entourages", ["uuid_v2"], name: "index_entourages_on_uuid_v2", unique: true, using: :btree

  create_table "entourages_users", force: :cascade do |t|
    t.integer  "user_id",                               null: false
    t.integer  "entourage_id",                          null: false
    t.string   "status",            default: "pending", null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.datetime "last_message_read"
  end

  add_index "entourages_users", ["user_id", "entourage_id"], name: "index_entourages_users_on_user_id_and_entourage_id", unique: true, using: :btree

# Could not dump table "events" because of following StandardError
#   Unknown type 'event_name' for column 'name'

  create_table "experimental_pending_request_reminders", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "experimental_pending_request_reminders", ["user_id"], name: "index_experimental_pending_request_reminders_on_user_id", using: :btree

  create_table "followings", force: :cascade do |t|
    t.integer "user_id",                   null: false
    t.integer "partner_id",                null: false
    t.boolean "active",     default: true, null: false
  end

  add_index "followings", ["partner_id"], name: "index_followings_on_partner_id", using: :btree
  add_index "followings", ["user_id", "partner_id"], name: "index_followings_on_user_id_and_partner_id", unique: true, using: :btree

  create_table "join_requests", force: :cascade do |t|
    t.integer  "user_id",                                                   null: false
    t.integer  "joinable_id",                                               null: false
    t.string   "joinable_type",                                             null: false
    t.string   "status",                                default: "pending", null: false
    t.text     "message"
    t.datetime "last_message_read"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.float    "distance"
    t.string   "role",                       limit: 11,                     null: false
    t.datetime "requested_at"
    t.datetime "accepted_at"
    t.datetime "email_notification_sent_at"
    t.datetime "archived_at"
  end

  add_index "join_requests", ["joinable_type", "joinable_id", "status"], name: "index_join_requests_on_joinable_type_and_joinable_id_and_status", using: :btree
  add_index "join_requests", ["user_id", "joinable_id", "joinable_type", "status"], name: "index_user_joinable_on_join_requests", using: :btree
  add_index "join_requests", ["user_id", "joinable_id", "joinable_type"], name: "index_join_requests_on_user_id_and_joinable_id", using: :btree

  create_table "login_histories", force: :cascade do |t|
    t.integer  "user_id",      null: false
    t.datetime "connected_at", null: false
  end

  add_index "login_histories", ["user_id"], name: "index_login_histories_on_connected_at_by_hour", unique: true, using: :btree

  create_table "marketing_referers", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.string   "content",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
  end

  create_table "moderation_areas", force: :cascade do |t|
    t.string  "departement",                    limit: 2,  null: false
    t.string  "name",                                      null: false
    t.integer "moderator_id"
    t.text    "welcome_message_1"
    t.text    "welcome_message_2"
    t.string  "slack_channel",                  limit: 80
    t.text    "welcome_message_1_offer_help"
    t.text    "welcome_message_2_offer_help"
    t.text    "welcome_message_1_ask_for_help"
    t.text    "welcome_message_2_ask_for_help"
    t.text    "welcome_message_1_organization"
    t.text    "welcome_message_2_organization"
  end

  add_index "moderation_areas", ["departement"], name: "index_moderation_areas_on_departement", unique: true, using: :btree

  create_table "moderator_reads", force: :cascade do |t|
    t.integer  "user_id",          null: false
    t.integer  "moderatable_id",   null: false
    t.string   "moderatable_type", null: false
    t.datetime "read_at",          null: false
  end

  add_index "moderator_reads", ["user_id", "moderatable_id", "moderatable_type"], name: "index_moderator_reads_on_user_id_and_moderatable", using: :btree

  create_table "newsletter_subscriptions", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "phone"
    t.string   "address"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "logo_url"
    t.string   "local_entity"
    t.string   "email"
    t.string   "website_url"
    t.boolean  "test_organization", default: false, null: false
    t.text     "tour_report_cc"
  end

  add_index "organizations", ["name"], name: "index_organizations_on_name", unique: true, using: :btree

  create_table "partner_invitations", force: :cascade do |t|
    t.integer  "partner_id",         null: false
    t.integer  "inviter_id",         null: false
    t.string   "invitee_email",      null: false
    t.string   "invitee_name"
    t.string   "invitee_role_title"
    t.integer  "invitee_id"
    t.string   "token",              null: false
    t.datetime "invited_at",         null: false
    t.datetime "accepted_at"
    t.datetime "deleted_at"
    t.string   "status",             null: false
  end

  add_index "partner_invitations", ["partner_id", "invitee_email"], name: "index_pending_partner_invitations_on_partner_and_invitee_email", unique: true, where: "((status)::text = 'pending'::text)", using: :btree
  add_index "partner_invitations", ["partner_id", "invitee_id"], name: "index_accepted_partner_invitations_on_partner_and_invitee_id", unique: true, where: "((status)::text = 'accepted'::text)", using: :btree
  add_index "partner_invitations", ["token"], name: "index_partner_invitations_on_token", unique: true, using: :btree

  create_table "partner_join_requests", force: :cascade do |t|
    t.integer  "user_id",            null: false
    t.integer  "partner_id"
    t.string   "postal_code"
    t.string   "new_partner_name"
    t.string   "partner_role_title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "partner_join_requests", ["user_id"], name: "index_partner_join_requests_on_user_id", using: :btree

  create_table "partners", force: :cascade do |t|
    t.string   "name",                       null: false
    t.string   "large_logo_url"
    t.string   "small_logo_url"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.text     "description"
    t.string   "phone"
    t.string   "address"
    t.string   "website_url"
    t.string   "email"
    t.text     "volunteers_needs"
    t.text     "donations_needs"
    t.string   "postal_code",      limit: 8
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "pois", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "adress",      limit: 255
    t.string   "phone",       limit: 255
    t.string   "website",     limit: 255
    t.string   "email",       limit: 255
    t.string   "audience",    limit: 255
    t.integer  "category_id"
    t.boolean  "validated",               default: false, null: false
    t.integer  "partner_id"
  end

  add_index "pois", ["category_id", "latitude", "longitude"], name: "index_pois_on_category_id_and_latitude_and_longitude", where: "validated", using: :btree
  add_index "pois", ["latitude", "longitude"], name: "index_pois_on_latitude_and_longitude", using: :btree
  add_index "pois", ["partner_id"], name: "index_pois_on_partner_id", unique: true, using: :btree

  create_table "questions", force: :cascade do |t|
    t.string   "title",           null: false
    t.string   "answer_type",     null: false
    t.integer  "organization_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "questions", ["organization_id"], name: "index_questions_on_organization_id", using: :btree

  create_table "registration_requests", force: :cascade do |t|
    t.string   "status",     default: "pending", null: false
    t.string   "extra",                          null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "rpush_apps", force: :cascade do |t|
    t.string   "name",                                null: false
    t.string   "environment"
    t.text     "certificate"
    t.string   "password"
    t.integer  "connections",             default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                                null: false
    t.string   "auth_key"
    t.string   "client_id"
    t.string   "client_secret"
    t.string   "access_token"
    t.datetime "access_token_expiration"
    t.text     "apn_key"
    t.string   "apn_key_id"
    t.string   "team_id"
    t.string   "bundle_id"
  end

  create_table "rpush_feedback", force: :cascade do |t|
    t.string   "device_token"
    t.datetime "failed_at",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "app_id"
  end

  add_index "rpush_feedback", ["device_token"], name: "index_rpush_feedback_on_device_token", using: :btree

  create_table "rpush_notifications", force: :cascade do |t|
    t.integer  "badge"
    t.string   "device_token"
    t.string   "sound"
    t.text     "alert"
    t.text     "data"
    t.integer  "expiry",             default: 86400
    t.boolean  "delivered",          default: false, null: false
    t.datetime "delivered_at"
    t.boolean  "failed",             default: false, null: false
    t.datetime "failed_at"
    t.integer  "error_code"
    t.text     "error_description"
    t.datetime "deliver_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "alert_is_json",      default: false, null: false
    t.string   "type",                               null: false
    t.string   "collapse_key"
    t.boolean  "delay_while_idle",   default: false, null: false
    t.text     "registration_ids"
    t.integer  "app_id",                             null: false
    t.integer  "retries",            default: 0
    t.string   "uri"
    t.datetime "fail_after"
    t.boolean  "processing",         default: false, null: false
    t.integer  "priority"
    t.text     "url_args"
    t.string   "category"
    t.boolean  "content_available",  default: false, null: false
    t.text     "notification"
    t.boolean  "mutable_content",    default: false, null: false
    t.string   "external_device_id"
    t.string   "thread_id"
  end

  add_index "rpush_notifications", ["delivered", "failed", "processing", "deliver_after", "created_at"], name: "index_rpush_notifications_multi", where: "((NOT delivered) AND (NOT failed))", using: :btree

  create_table "sensitive_words", force: :cascade do |t|
    t.string "raw",                         null: false
    t.string "pattern",                     null: false
    t.string "match_type", default: "stem", null: false
    t.string "scope",      default: "all",  null: false
    t.string "category"
  end

  add_index "sensitive_words", ["pattern"], name: "index_sensitive_words_on_pattern", unique: true, using: :btree

  create_table "sensitive_words_checks", force: :cascade do |t|
    t.string   "status",      null: false
    t.integer  "record_id",   null: false
    t.string   "record_type", null: false
    t.text     "matches",     null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "sensitive_words_checks", ["record_type", "record_id"], name: "index_sensitive_words_checks_on_record_type_and_record_id", unique: true, using: :btree

  create_table "session_histories", id: false, force: :cascade do |t|
    t.integer "user_id",                              null: false
    t.date    "date",                                 null: false
    t.string  "platform",                  limit: 7,  null: false
    t.string  "notifications_permissions", limit: 14
  end

  add_index "session_histories", ["user_id", "platform", "date"], name: "index_session_histories_on_user_id_and_platform_and_date", unique: true, using: :btree

  create_table "simplified_tour_points", force: :cascade do |t|
    t.float    "latitude",   null: false
    t.float    "longitude",  null: false
    t.integer  "tour_id",    null: false
    t.datetime "created_at"
  end

  add_index "simplified_tour_points", ["latitude", "longitude", "tour_id"], name: "index_simplified_tour_points_on_coordinates_and_tour_id", using: :btree
  add_index "simplified_tour_points", ["tour_id"], name: "index_simplified_tour_points_on_tour_id", using: :btree

# Could not dump table "sms_deliveries" because of following StandardError
#   Unknown type 'sms_delivery_status' for column 'status'

  create_table "store_daily_reports", force: :cascade do |t|
    t.string   "store_id"
    t.string   "app_name"
    t.date     "report_date"
    t.integer  "nb_downloads"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "store_daily_reports", ["report_date", "app_name", "store_id"], name: "index_store_daily_reports_date_store_app", unique: true, using: :btree

  create_table "suggestion_compute_histories", force: :cascade do |t|
    t.integer  "user_number",                               null: false
    t.integer  "total_user_number",                         null: false
    t.integer  "entourage_number",                          null: false
    t.integer  "total_entourage_number",                    null: false
    t.integer  "duration",                                  null: false
    t.string   "filter_type",            default: "NORMAL", null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "tour_points", force: :cascade do |t|
    t.float    "latitude",     null: false
    t.float    "longitude",    null: false
    t.integer  "tour_id",      null: false
    t.datetime "passing_time", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tour_points", ["tour_id", "created_at"], name: "index_tour_points_on_tour_id_and_created_at", using: :btree
  add_index "tour_points", ["tour_id", "id"], name: "index_tour_points_on_tour_id_and_id", using: :btree
  add_index "tour_points", ["tour_id", "latitude", "longitude"], name: "index_tour_points_on_tour_id_and_latitude_and_longitude", using: :btree

  create_table "tours", force: :cascade do |t|
    t.string   "tour_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
    t.integer  "vehicle_type",     default: 0
    t.integer  "user_id"
    t.datetime "closed_at"
    t.integer  "length",           default: 0
    t.integer  "encounters_count", default: 0, null: false
    t.integer  "number_of_people", default: 0, null: false
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "feed_updated_at"
  end

  add_index "tours", ["latitude", "longitude"], name: "index_tours_on_latitude_and_longitude", using: :btree
  add_index "tours", ["user_id", "updated_at", "tour_type"], name: "index_tours_on_user_id_and_updated_at_and_tour_type", using: :btree

  create_table "tours_users", force: :cascade do |t|
    t.integer  "user_id",                               null: false
    t.integer  "tour_id",                               null: false
    t.string   "status",            default: "pending", null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.datetime "last_message_read"
  end

  add_index "tours_users", ["user_id", "tour_id"], name: "index_tours_users_on_user_id_and_tour_id", unique: true, using: :btree

  create_table "user_applications", force: :cascade do |t|
    t.string   "push_token",                null: false
    t.string   "device_os",                 null: false
    t.string   "version",                   null: false
    t.integer  "user_id",                   null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "device_family"
    t.string   "notifications_permissions"
  end

  add_index "user_applications", ["push_token"], name: "index_user_applications_on_push_token", unique: true, using: :btree
  add_index "user_applications", ["user_id", "device_family"], name: "index_user_applications_on_user_id_and_device_family", using: :btree

  create_table "user_moderations", force: :cascade do |t|
    t.integer "user_id",                     null: false
    t.string  "expectations"
    t.string  "acquisition_channel"
    t.string  "content_sent"
    t.string  "skills"
    t.boolean "accepts_event_invitations"
    t.boolean "accepts_volunteering_offers"
    t.boolean "ambassador"
  end

  add_index "user_moderations", ["user_id"], name: "index_user_moderations_on_user_id", unique: true, using: :btree

  create_table "user_newsfeeds", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.float    "latitude",   null: false
    t.float    "longitude",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_newsfeeds", ["user_id"], name: "index_user_newsfeeds_on_user_id", using: :btree

  create_table "user_relationships", force: :cascade do |t|
    t.integer "source_user_id", null: false
    t.integer "target_user_id", null: false
    t.string  "relation_type",  null: false
  end

  add_index "user_relationships", ["source_user_id", "target_user_id", "relation_type"], name: "unique_user_relationship", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                        limit: 255
    t.string   "first_name",                   limit: 255
    t.string   "last_name",                    limit: 255
    t.string   "phone",                                                                  null: false
    t.string   "token",                        limit: 255
    t.string   "device_id"
    t.integer  "device_type"
    t.string   "sms_code"
    t.integer  "organization_id"
    t.boolean  "manager",                                  default: false,               null: false
    t.float    "default_latitude"
    t.float    "default_longitude"
    t.boolean  "admin",                                    default: false,               null: false
    t.string   "user_type",                                default: "pro",               null: false
    t.string   "avatar_key"
    t.string   "validation_status",                        default: "validated",         null: false
    t.boolean  "deleted",                                  default: false,               null: false
    t.integer  "marketing_referer_id",                     default: 1,                   null: false
    t.datetime "last_sign_in_at"
    t.boolean  "atd_friend",                               default: false,               null: false
    t.boolean  "use_suggestions",                          default: false,               null: false
    t.string   "about",                        limit: 200
    t.string   "community",                    limit: 9,                                 null: false
    t.string   "encrypted_password"
    t.jsonb    "roles",                                    default: [],                  null: false
    t.datetime "first_sign_in_at"
    t.datetime "onboarding_sequence_start_at"
    t.integer  "address_id"
    t.boolean  "accepts_emails_deprecated",                default: true,                null: false
    t.datetime "last_email_sent_at"
    t.string   "targeting_profile"
    t.integer  "partner_id"
    t.boolean  "partner_admin",                            default: false,               null: false
    t.string   "partner_role_title"
    t.uuid     "uuid",                                     default: "gen_random_uuid()"
    t.string   "goal"
    t.jsonb    "interests",                                default: [],                  null: false
  end

  add_index "users", ["address_id"], name: "index_users_on_address_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["organization_id"], name: "index_users_on_organization_id", using: :btree
  add_index "users", ["partner_id"], name: "index_users_on_partner_id", using: :btree
  add_index "users", ["phone", "community"], name: "index_users_on_phone_and_community", unique: true, using: :btree
  add_index "users", ["roles"], name: "index_users_on_roles", using: :gin
  add_index "users", ["token"], name: "index_users_on_token", unique: true, using: :btree
  add_index "users", ["uuid"], name: "index_users_on_uuid", unique: true, using: :btree

  create_table "users_appetences", force: :cascade do |t|
    t.integer  "user_id",                                null: false
    t.integer  "appetence_social",       default: 0,     null: false
    t.integer  "appetence_mat_help",     default: 0,     null: false
    t.integer  "appetence_non_mat_help", default: 0,     null: false
    t.float    "avg_dist",               default: 150.0, null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "users_appetences", ["user_id"], name: "index_users_appetences_on_user_id", unique: true, using: :btree

  add_foreign_key "experimental_pending_request_reminders", "users"
  add_foreign_key "users", "addresses"
end
