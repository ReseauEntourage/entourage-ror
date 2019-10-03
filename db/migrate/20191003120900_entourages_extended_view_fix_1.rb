class EntouragesExtendedViewFix1 < ActiveRecord::Migration
  def up
    sql = <<-SQL
      create or replace view entourages_extended as
        select
          status,
          title,

          -- entourage_type: normalize for events
          case group_type
            when 'outing' then 'event'
            else entourage_type
          end as entourage_type,

          user_id,
          latitude,
          longitude,
          number_of_people,

          -- timestamps: convert to Europe/Paris timezone
          timezone('Europe/Paris', created_at at time zone 'UTC') as created_at,
          timezone('Europe/Paris', updated_at at time zone 'UTC') as updated_at,

          description,
          uuid,

          -- category, -- confusing and almost never useful
          -- use_suggestions, -- never useful

          -- display_category: normalize for events
          case group_type
            when 'outing' then 'event'
            else display_category
          end as display_category,

          uuid_v2,
          postal_code,
          country,

          -- additional field: departement
          case
            when country != 'FR' then 'hors FR'
            else substring(postal_code for 2)
          end as departement,

          -- additional field: zone
          case
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

          community,

          -- group_type: normalize for events
          case group_type
            when 'outing' then 'event'
            else group_type
          end as group_type,

          metadata,
          public,
          feed_updated_at,

          id

        from entourages

        where community = 'entourage' -- exlude PFP
          and group_type in ('action', 'outing') -- exclude conversations
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      create or replace view entourages_extended as
        select
          status,
          title,

          -- entourage_type: normalize for events
          case group_type
            when 'outing' then 'event'
            else entourage_type
          end as entourage_type,

          user_id,
          latitude,
          longitude,
          number_of_people,

          -- timestamps: convert to Europe/Paris timezone
          timezone('Europe/Paris', created_at at time zone 'UTC') as created_at,
          timezone('Europe/Paris', updated_at at time zone 'UTC') as updated_at,

          description,
          uuid,

          -- category, -- confusing and almost never useful
          -- use_suggestions, -- never useful

          -- display_category: normalize for events
          case group_type
            when 'outing' then 'event'
            else display_category
          end as display_category,

          uuid_v2,
          postal_code,
          country,

          -- additional field: departement
          case
            when country != 'FR' then 'hors FR'
            else substring(postal_code for 2)
          end as departement,

          -- additional field: zone
          case
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

          community,

          -- group_type: normalize for events
          case group_type
            when 'outing' then 'event'
            else group_type
          end as group_type,

          metadata,
          public,
          feed_updated_at

        from entourages

        where community = 'entourage' -- exlude PFP
          and group_type in ('action', 'outing') -- exclude conversations
    SQL

    execute(sql)
  end
end
