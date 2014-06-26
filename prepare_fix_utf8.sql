-- Any alterations that should be done before the utf8 fix should be placed in this file.

-- don't want to use utf8mb on schema_migrations
-- this table has a unique index on column 'version' which allows 255 characters (limit 767 bytes / 3 bytes per character). 
-- changing to utf8mb4 would reduce 'version' to a max of 191 characters (limit 767 bytes / 4 bytes per character).
-- ALTER TABLE schema_migrations CONVERT TO CHARACTER SET utf8;
