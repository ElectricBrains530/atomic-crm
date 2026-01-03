-- Fix deals contact_ids (initialize as empty array if null)
UPDATE "public"."deals" SET contact_ids = '{}' WHERE contact_ids IS NULL;

-- Fix deals index (assign sequential index per stage)
WITH indexed_deals AS (
  SELECT id, row_number() OVER (PARTITION BY stage ORDER BY created_at) as rn
  FROM "public"."deals"
)
UPDATE "public"."deals" d
SET index = id_d.rn
FROM indexed_deals id_d
WHERE d.id = id_d.id;
