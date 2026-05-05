class PartitionJoinRequestsByTypeAndYear < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  JOINABLE_TYPES = %w[Entourage Neighborhood Smalltalk].freeze
  YEAR_RANGE = (2015..2035).freeze

  COLUMNS = %w[
    id user_id joinable_id joinable_type status message last_message_read
    created_at updated_at distance role requested_at accepted_at
    email_notification_sent_at archived_at confirmed_at
    unread_messages_count salesforce_id participate_at
  ].freeze

  def up
    # Step 1: Move existing table aside, freeing up the name and its index names.
    execute "ALTER TABLE join_requests RENAME TO join_requests_unpartitioned"
    execute "ALTER TABLE join_requests_unpartitioned RENAME CONSTRAINT join_requests_pkey TO join_requests_unpartitioned_pkey"
    execute "DROP INDEX index_join_requests_on_joinable_type_and_joinable_id"
    execute "DROP INDEX index_join_requests_on_participate_at"
    execute "DROP INDEX index_join_requests_on_user_id_and_joinable"
    execute "DROP INDEX index_join_requests_on_user_id"

    # Step 2: Create the partitioned parent table.
    # PK must include all partition keys (joinable_type + created_at) per PostgreSQL requirement.
    # id uniqueness is enforced globally by the shared sequence, not by the PK constraint.
    execute <<~SQL
      CREATE TABLE join_requests (
        id             integer                     NOT NULL DEFAULT nextval('join_requests_id_seq'),
        user_id        integer                     NOT NULL,
        joinable_id    integer                     NOT NULL,
        joinable_type  character varying           NOT NULL,
        status         character varying           NOT NULL DEFAULT 'pending',
        message        text,
        last_message_read timestamp without time zone,
        created_at     timestamp without time zone NOT NULL,
        updated_at     timestamp without time zone NOT NULL,
        distance       double precision,
        role           character varying(11)       NOT NULL,
        requested_at   timestamp without time zone,
        accepted_at    timestamp without time zone,
        email_notification_sent_at timestamp without time zone,
        archived_at    timestamp without time zone,
        confirmed_at   timestamp without time zone,
        unread_messages_count integer,
        salesforce_id  character varying,
        participate_at timestamp without time zone,
        CONSTRAINT join_requests_pkey PRIMARY KEY (id, joinable_type, created_at)
      ) PARTITION BY LIST (joinable_type)
    SQL

    execute "ALTER SEQUENCE join_requests_id_seq OWNED BY join_requests.id"

    # Step 3: Create one list partition per known joinable_type,
    # each sub-partitioned by RANGE on created_at year.
    JOINABLE_TYPES.each do |type|
      type_table = "join_requests_#{type.downcase}"

      execute <<~SQL
        CREATE TABLE #{type_table} PARTITION OF join_requests
          FOR VALUES IN ('#{type}')
          PARTITION BY RANGE (created_at)
      SQL

      YEAR_RANGE.each do |year|
        execute <<~SQL
          CREATE TABLE #{type_table}_#{year} PARTITION OF #{type_table}
            FOR VALUES FROM ('#{year}-01-01') TO ('#{year + 1}-01-01')
        SQL
      end

      # Catch-all for any year outside YEAR_RANGE
      execute "CREATE TABLE #{type_table}_default PARTITION OF #{type_table} DEFAULT"
    end

    # Catch-all for any joinable_type not listed above, also sub-partitioned by year
    execute <<~SQL
      CREATE TABLE join_requests_other PARTITION OF join_requests
        DEFAULT
        PARTITION BY RANGE (created_at)
    SQL

    YEAR_RANGE.each do |year|
      execute <<~SQL
        CREATE TABLE join_requests_other_#{year} PARTITION OF join_requests_other
          FOR VALUES FROM ('#{year}-01-01') TO ('#{year + 1}-01-01')
      SQL
    end

    execute "CREATE TABLE join_requests_other_default PARTITION OF join_requests_other DEFAULT"

    # Step 4: Copy all existing data.
    # Explicit column list guards against column-order mismatches.
    cols = COLUMNS.join(", ")
    execute "INSERT INTO join_requests (#{cols}) SELECT #{cols} FROM join_requests_unpartitioned"

    # Step 5: Recreate indexes (applied to the parent, inherited by all partitions).
    execute "CREATE INDEX index_join_requests_on_joinable_type_and_joinable_id ON join_requests (joinable_type, joinable_id)"
    execute "CREATE INDEX index_join_requests_on_participate_at ON join_requests (participate_at)"
    execute "CREATE INDEX index_join_requests_on_user_id_and_joinable ON join_requests (user_id, joinable_id, joinable_type)"
    execute "CREATE INDEX index_join_requests_on_user_id ON join_requests (user_id)"

    say "join_requests_unpartitioned kept as backup — verify data, then drop manually."
  end

  def down
    # Transfer sequence ownership back before dropping so the sequence survives CASCADE.
    execute "ALTER SEQUENCE join_requests_id_seq OWNED BY join_requests_unpartitioned.id"
    execute "DROP TABLE join_requests CASCADE"
    execute "ALTER TABLE join_requests_unpartitioned RENAME TO join_requests"
    execute "ALTER TABLE join_requests RENAME CONSTRAINT join_requests_unpartitioned_pkey TO join_requests_pkey"
    execute "CREATE INDEX index_join_requests_on_joinable_type_and_joinable_id ON join_requests (joinable_type, joinable_id)"
    execute "CREATE INDEX index_join_requests_on_participate_at ON join_requests (participate_at)"
    execute "CREATE INDEX index_join_requests_on_user_id_and_joinable ON join_requests (user_id, joinable_id, joinable_type)"
    execute "CREATE INDEX index_join_requests_on_user_id ON join_requests (user_id)"
  end
end
