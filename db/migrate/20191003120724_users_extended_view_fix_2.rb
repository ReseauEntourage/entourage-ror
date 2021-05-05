class UsersExtendedViewFix2 < ActiveRecord::Migration[4.2]
  def up
    sql = <<-SQL
      create or replace view users_extended as
        select
          -- timestamps: convert to Europe/Paris timezone
          timezone('Europe/Paris', users.created_at at time zone 'UTC') as created_at,
          timezone('Europe/Paris', users.updated_at at time zone 'UTC') as updated_at,

          email,
          first_name,
          last_name,
          -- phone,
          -- token,
          -- device_id,
          -- device_type,
          -- sms_code,
          organization_id,
          manager,
          -- default_latitude,
          -- default_longitude,
          admin,
          user_type,
          avatar_key,
          validation_status,
          deleted,
          -- marketing_referer_id,

          timezone('Europe/Paris', last_sign_in_at at time zone 'UTC') as last_sign_in_at,

          atd_friend,
          -- use_suggestions,
          about,
          community,

          encrypted_password is not null as has_encrypted_password,

          roles,

          timezone('Europe/Paris', first_sign_in_at at time zone 'UTC') as first_sign_in_at,
          timezone('Europe/Paris', onboarding_sequence_start_at at time zone 'UTC') as onboarding_sequence_start_at,

          address_id,
          -- accepts_emails_deprecated,

          timezone('Europe/Paris', last_email_sent_at at time zone 'UTC') as last_email_sent_at,

          targeting_profile,
          partner_id,

          addresses.id is not null as has_action_zone,

          -- additional field: departement
          case
            when addresses is null then 'pas de zone d''action'
            when country != 'FR'   then 'hors FR'
            else substring(postal_code for 2)
          end as departement,

          -- additional field: zone
          case
            when addresses is null                   then 'pas de zone d''action'
            when country != 'FR'                     then 'hors FR'
            when substring(postal_code for 2) = '75' then 'Paris (75)'
            when substring(postal_code for 2) = '92' then 'Hauts-de-Seine (92)'
            when substring(postal_code for 2) = '69' then 'Lyon (69)'
            when substring(postal_code for 2) = '59' then 'Lille (59)'
            when substring(postal_code for 2) = '35' then 'Rennes (35)'
            else                                          'hors zone'
          end as zone,

          -- additional field: in_zone
          (country = 'FR' and
           substring(postal_code for 2) in ('75', '92', '69', '59', '35'))
          as in_zone,

          users.id

        from users
        left join addresses on addresses.id = address_id

        where community = 'entourage'
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      create or replace view users_extended as
        select
          -- timestamps: convert to Europe/Paris timezone
          timezone('Europe/Paris', users.created_at at time zone 'UTC') as created_at,
          timezone('Europe/Paris', users.updated_at at time zone 'UTC') as updated_at,

          email,
          first_name,
          last_name,
          -- phone,
          -- token,
          -- device_id,
          -- device_type,
          -- sms_code,
          organization_id,
          manager,
          -- default_latitude,
          -- default_longitude,
          admin,
          user_type,
          avatar_key,
          validation_status,
          deleted,
          -- marketing_referer_id,

          timezone('Europe/Paris', last_sign_in_at at time zone 'UTC') as last_sign_in_at,

          atd_friend,
          -- use_suggestions,
          about,
          community,

          encrypted_password is not null as has_encrypted_password,

          roles,

          timezone('Europe/Paris', first_sign_in_at at time zone 'UTC') as first_sign_in_at,
          timezone('Europe/Paris', onboarding_sequence_start_at at time zone 'UTC') as onboarding_sequence_start_at,

          address_id,
          -- accepts_emails_deprecated,

          timezone('Europe/Paris', last_email_sent_at at time zone 'UTC') as last_email_sent_at,

          targeting_profile,
          partner_id,

          addresses.id is not null as has_action_zone,

          -- additional field: departement
          case
            when addresses is null then 'pas de zone d''action'
            when country != 'FR'   then 'hors FR'
            else substring(postal_code for 2)
          end as departement,

          -- additional field: zone
          case
            when addresses is null                   then 'pas de zone d''action'
            when country != 'FR'                     then 'hors FR'
            when substring(postal_code for 2) = '75' then 'Paris (75)'
            when substring(postal_code for 2) = '92' then 'Hauts-de-Seine (92)'
            when substring(postal_code for 2) = '69' then 'Lyon (69)'
            when substring(postal_code for 2) = '59' then 'Lille (59)'
            when substring(postal_code for 2) = '35' then 'Rennes (35)'
            else                                          'hors zone'
          end as zone,

          -- additional field: in_zone
          (country = 'FR' and
           substring(postal_code for 2) in ('75', '92', '69', '59', '35'))
          as in_zone

        from users
        left join addresses on addresses.id = address_id

        where community = 'entourage'
    SQL

    execute(sql)
  end
end
