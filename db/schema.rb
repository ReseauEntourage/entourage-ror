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

ActiveRecord::Schema.define(version: 20181211133039) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "postgis"

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
    t.string   "place_name",                null: false
    t.string   "street_address"
    t.float    "latitude",                  null: false
    t.float    "longitude",                 null: false
    t.string   "postal_code",     limit: 8
    t.string   "country",         limit: 2
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "google_place_id"
  end

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

  create_table "authentication_providers", force: :cascade do |t|
    t.integer  "user_id",     null: false
    t.string   "provider",    null: false
    t.integer  "provider_id", null: false
    t.string   "type",        null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "authentication_providers", ["user_id", "provider"], name: "index_authentication_providers_on_user_id_and_provider", unique: true, using: :btree

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
  end

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

  create_table "email_deliveries", force: :cascade do |t|
    t.integer  "user_id",  null: false
    t.string   "campaign", null: false
    t.datetime "sent_at",  null: false
  end

  add_index "email_deliveries", ["user_id", "campaign"], name: "index_email_deliveries_on_user_id_and_campaign", using: :btree

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
    t.string  "moderator"
    t.string  "moderation_action"
    t.text    "moderation_comment"
    t.date    "action_outcome_reported_at"
    t.string  "action_outcome"
    t.string  "action_success_reason"
    t.string  "action_failure_reason"
  end

  add_index "entourage_moderations", ["entourage_id"], name: "index_entourage_moderations_on_entourage_id", unique: true, using: :btree

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

  create_table "experimental_pending_request_reminders", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "experimental_pending_request_reminders", ["user_id"], name: "index_experimental_pending_request_reminders_on_user_id", using: :btree

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

  create_table "partners", force: :cascade do |t|
    t.string   "name",           null: false
    t.string   "large_logo_url", null: false
    t.string   "small_logo_url", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.text     "description"
    t.string   "phone"
    t.string   "address"
    t.string   "website_url"
    t.string   "email"
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
  end

  add_index "pois", ["category_id", "latitude", "longitude"], name: "index_pois_on_category_id_and_latitude_and_longitude", where: "validated", using: :btree
  add_index "pois", ["latitude", "longitude"], name: "index_pois_on_latitude_and_longitude", using: :btree

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
  end

  create_table "rpush_feedback", force: :cascade do |t|
    t.string   "device_token", limit: 64, null: false
    t.datetime "failed_at",               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "app_id"
  end

  add_index "rpush_feedback", ["device_token"], name: "index_rpush_feedback_on_device_token", using: :btree

  create_table "rpush_notifications", force: :cascade do |t|
    t.integer  "badge"
    t.string   "device_token",      limit: 64
    t.string   "sound",                        default: "default"
    t.text     "alert"
    t.text     "data"
    t.integer  "expiry",                       default: 86400
    t.boolean  "delivered",                    default: false,     null: false
    t.datetime "delivered_at"
    t.boolean  "failed",                       default: false,     null: false
    t.datetime "failed_at"
    t.integer  "error_code"
    t.text     "error_description"
    t.datetime "deliver_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "alert_is_json",                default: false
    t.string   "type",                                             null: false
    t.string   "collapse_key"
    t.boolean  "delay_while_idle",             default: false,     null: false
    t.text     "registration_ids"
    t.integer  "app_id",                                           null: false
    t.integer  "retries",                      default: 0
    t.string   "uri"
    t.datetime "fail_after"
    t.boolean  "processing",                   default: false,     null: false
    t.integer  "priority"
    t.text     "url_args"
    t.string   "category"
    t.boolean  "content_available",            default: false
    t.text     "notification"
  end

  add_index "rpush_notifications", ["delivered", "failed"], name: "index_rpush_notifications_multi", where: "((NOT delivered) AND (NOT failed))", using: :btree

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
    t.integer "user_id",            null: false
    t.date    "date",               null: false
    t.string  "platform", limit: 7, null: false
  end

  add_index "session_histories", ["user_id", "platform", "date"], name: "index_session_histories_on_user_id_and_platform_and_date", unique: true, using: :btree

  create_table "simplified_tour_points", force: :cascade do |t|
    t.float    "latitude",   null: false
    t.float    "longitude",  null: false
    t.integer  "tour_id",    null: false
    t.datetime "created_at"
  end

  add_index "simplified_tour_points", ["tour_id"], name: "index_simplified_tour_points_on_tour_id", using: :btree

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
    t.string   "push_token",    null: false
    t.string   "device_os",     null: false
    t.string   "version",       null: false
    t.integer  "user_id",       null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "device_family"
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

  create_table "user_partners", force: :cascade do |t|
    t.integer  "user_id",                    null: false
    t.integer  "partner_id",                 null: false
    t.boolean  "default",    default: false, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "user_partners", ["user_id", "partner_id"], name: "index_user_partners_on_user_id_and_partner_id", unique: true, using: :btree
  add_index "user_partners", ["user_id"], name: "index_user_partners_on_user_id", where: "\"default\"", using: :btree

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
    t.string   "phone",                                                          null: false
    t.string   "token",                        limit: 255
    t.string   "device_id"
    t.integer  "device_type"
    t.string   "sms_code"
    t.integer  "organization_id"
    t.boolean  "manager",                                  default: false,       null: false
    t.float    "default_latitude"
    t.float    "default_longitude"
    t.boolean  "admin",                                    default: false,       null: false
    t.string   "user_type",                                default: "pro",       null: false
    t.string   "avatar_key"
    t.string   "validation_status",                        default: "validated", null: false
    t.boolean  "deleted",                                  default: false,       null: false
    t.integer  "marketing_referer_id",                     default: 1,           null: false
    t.datetime "last_sign_in_at"
    t.boolean  "atd_friend",                               default: false,       null: false
    t.boolean  "use_suggestions",                          default: false,       null: false
    t.string   "about",                        limit: 200
    t.string   "community",                    limit: 9,                         null: false
    t.string   "encrypted_password"
    t.jsonb    "roles",                                    default: [],          null: false
    t.datetime "first_sign_in_at"
    t.datetime "onboarding_sequence_start_at"
    t.integer  "address_id"
    t.boolean  "accepts_emails",                           default: true,        null: false
  end

  add_index "users", ["address_id"], name: "index_users_on_address_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["organization_id"], name: "index_users_on_organization_id", using: :btree
  add_index "users", ["phone", "community"], name: "index_users_on_phone_and_community", unique: true, using: :btree
  add_index "users", ["roles"], name: "index_users_on_roles", using: :gin
  add_index "users", ["token"], name: "index_users_on_token", unique: true, using: :btree

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
