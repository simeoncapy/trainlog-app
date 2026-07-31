-- Older versions of the app parsed the server's `created` / `last_modified`
-- values as local time, so they were cached without the trailing UTC 'Z'
-- designator. The digits themselves were already UTC, so only the marker is
-- missing: appending 'Z' is enough and no clock value is shifted.
-- Rows written by the current app already end with 'Z', and the guards below
-- skip anything that already carries a zone designator or a numeric offset,
-- which makes this a no-op on a fresh install (empty table) and on rows that
-- are already correct.
UPDATE trips
SET created = created || 'Z'
WHERE created IS NOT NULL
  AND TRIM(created) <> ''
  AND created NOT LIKE '%Z'
  AND created NOT GLOB '*[+-][0-9][0-9]:[0-9][0-9]'
  AND created NOT GLOB '*[+-][0-9][0-9][0-9][0-9]';

UPDATE trips
SET last_modified = last_modified || 'Z'
WHERE last_modified IS NOT NULL
  AND TRIM(last_modified) <> ''
  AND last_modified NOT LIKE '%Z'
  AND last_modified NOT GLOB '*[+-][0-9][0-9]:[0-9][0-9]'
  AND last_modified NOT GLOB '*[+-][0-9][0-9][0-9][0-9]'
