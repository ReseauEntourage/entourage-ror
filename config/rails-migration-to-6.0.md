# Railties

## Removals

 - Remove deprecated environment argument from the rails commands

# Active Record

## Removals
 - [ok] Remove deprecated #set_state from the transaction object.
 - [ok] Remove deprecated #supports_statement_cache? from the database adapters.
 - [ok] Remove deprecated #insert_fixtures from the database adapters.
 - [ok] Remove deprecated ActiveRecord::ConnectionAdapters::SQLite3Adapter#valid_alter_table_type?.
 - Remove support for passing the column name to sum when a block is passed.
 - Remove support for passing the column name to count when a block is passed.
 - Remove support for delegation of missing methods in a relation to Arel.
 - Remove support for delegating missing methods in a relation to private methods of the class.
 - Remove support for specifying a timestamp name for #cache_key.
 - [ok] Remove deprecated ActiveRecord::Migrator.migrations_path=.
 - [ok] Remove deprecated expand_hash_conditions_for_aggregates.

# Active Storage

## Removals

 - Deprecate config.active_storage.queue in favor of config.active_storage.queues.analysis and config.active_storage.queues.purge.
 - Deprecate ActiveStorage::Downloading in favor of ActiveStorage::Blob#open.
 - Deprecate using mini_magick directly for generating image variants in favor of image_processing.
 - Deprecate :combine_options in Active Storage's ImageProcessing transformer without replacement.

# Active Support

## Removals

 - Remove deprecated #acronym_regex method from Inflections.
 - Remove deprecated Module#reachable? method.
 - Remove Kernel#` without any replacement.
