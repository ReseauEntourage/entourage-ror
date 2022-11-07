class CreateDenormDailyEngagements < ActiveRecord::Migration[5.2]
  def up
    create_table :denorm_daily_engagements do |t|
      t.date :date, null: false
      t.integer :user_id, null: false
      t.string :postal_code

      t.index [:date, :user_id, :postal_code], unique: true, name: 'unicity_denorm_daily_engagements_on_date_user_id_postal_code'
    end
  end

  def down
    remove_index :denorm_daily_engagements, [:date, :user_id, :postal_code]

    drop_table :denorm_daily_engagements
  end
end

#init this table with this request:
# insert into denorm_daily_engagements 
# select 
#       date(timezone('Europe/Paris', created_at at time zone 'UTC')),
#       user_id,
#       coalesce(case when country = 'FR' then postal_code end, 'unkown')
#     from entourages 
#     where entourages.community = 'entourage' and entourages.group_type in ('action', 'outing') /*and created_at >= ('2022-01-01')*/
# on conflict ("date", user_id, postal_code) do nothing;

# insert into denorm_daily_engagements 
# select 
#       date(timezone('Europe/Paris', chat_messages.created_at at time zone 'UTC')),
#       chat_messages.user_id,
#       coalesce(case when country = 'FR' then postal_code end, 'unkown') 
#     from chat_messages join entourages 
#       on messageable_type = 'Entourage' and messageable_id = entourages.id 
#       and entourages.community = 'entourage' and entourages.group_type in ('action', 'outing')
#     where message_type = 'text'  /*and chat_messages.created_at >= '2022-01-01'*/
# on conflict ("date", user_id, postal_code) do nothing;

# insert into denorm_daily_engagements 
# select  
#       date(timezone('Europe/Paris', chat_messages.created_at at time zone 'UTC')),
#       chat_messages.user_id,
#       coalesce(case when sender_addresses.country = 'FR' then sender_addresses.postal_code end, 'unkown')
#     from chat_messages join entourages 
#       on messageable_type = 'Entourage' and messageable_id = entourages.id 
#       and entourages.community = 'entourage' and entourages.group_type = 'conversation'
#     join users sender on sender.id = chat_messages.user_id
#     left join addresses sender_addresses on sender_addresses.id = address_id
#     where message_type = 'text' /*and chat_messages.created_at >= '2022-01-01'*/
# on conflict ("date", user_id, postal_code) do nothing;

# insert into denorm_daily_engagements 
# select  
#       date(timezone('Europe/Paris', coalesce(requested_at, join_requests.created_at) at time zone 'UTC')),
#       join_requests.user_id,
#       coalesce(case when country = 'FR' then postal_code end, 'unkown')
#     from join_requests join entourages 
#       on joinable_type = 'Entourage' and joinable_id = entourages.id 
#       and entourages.community = 'entourage' and entourages.group_type in ('action', 'outing')
#     where (group_type = 'outing' or (message is not null and trim(message, ' \n') != ''))
#     /*and coalesce(requested_at, join_requests.created_at) = '2022-01-01'*/
# on conflict ("date", user_id, postal_code) do nothing;
