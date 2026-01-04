-- 20260103170000_complete_multitenancy.sql

-- 1. Contact Notes
ALTER TABLE "public"."contactNotes" ADD COLUMN IF NOT EXISTS "organization_id" bigint REFERENCES "public"."organizations"("id") ON DELETE CASCADE;
-- Backfill: Link note to the same organization as the contact
UPDATE "public"."contactNotes" n
SET organization_id = c.organization_id
FROM "public"."contacts" c
WHERE n.contact_id = c.id AND n.organization_id IS NULL;

-- 2. Deal Notes
ALTER TABLE "public"."dealNotes" ADD COLUMN IF NOT EXISTS "organization_id" bigint REFERENCES "public"."organizations"("id") ON DELETE CASCADE;
-- Backfill: Link note to the same organization as the deal
UPDATE "public"."dealNotes" n
SET organization_id = d.organization_id
FROM "public"."deals" d
WHERE n.deal_id = d.id AND n.organization_id IS NULL;

-- 3. Tags
ALTER TABLE "public"."tags" ADD COLUMN IF NOT EXISTS "organization_id" bigint REFERENCES "public"."organizations"("id") ON DELETE CASCADE;
-- Backfill: orphan tags go to Org 1 (Demo)
UPDATE "public"."tags" SET organization_id = 1 WHERE organization_id IS NULL;

-- 4. Apply Triggers (Ensure force_tenant_id is used)
DROP TRIGGER IF EXISTS trg_force_tenant ON "public"."contactNotes";
CREATE TRIGGER trg_force_tenant BEFORE INSERT OR UPDATE ON "public"."contactNotes" FOR EACH ROW EXECUTE FUNCTION force_tenant_id();

DROP TRIGGER IF EXISTS trg_force_tenant ON "public"."dealNotes";
CREATE TRIGGER trg_force_tenant BEFORE INSERT OR UPDATE ON "public"."dealNotes" FOR EACH ROW EXECUTE FUNCTION force_tenant_id();

DROP TRIGGER IF EXISTS trg_force_tenant ON "public"."tags";
CREATE TRIGGER trg_force_tenant BEFORE INSERT OR UPDATE ON "public"."tags" FOR EACH ROW EXECUTE FUNCTION force_tenant_id();

-- 5. Enable RLS
ALTER TABLE "public"."contactNotes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."dealNotes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;

-- 6. Cleanup Old Permissive Policies
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."contactNotes";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."contactNotes";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."contactNotes";
DROP POLICY IF EXISTS "Contact Notes Delete Policy" ON "public"."contactNotes";
DROP POLICY IF EXISTS "Contact Notes Update policy" ON "public"."contactNotes";

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."dealNotes";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."dealNotes";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."dealNotes";
DROP POLICY IF EXISTS "Deal Notes Delete Policy" ON "public"."dealNotes";
DROP POLICY IF EXISTS "Deal Notes Update Policy" ON "public"."dealNotes";

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."tags";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."tags";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."tags";

-- 7. Add New Isolation Policies
CREATE POLICY "Tenant Isolation: ContactNotes" ON "public"."contactNotes" USING (organization_id = active_org_id()) WITH CHECK (organization_id = active_org_id());

CREATE POLICY "Tenant Isolation: DealNotes" ON "public"."dealNotes" USING (organization_id = active_org_id()) WITH CHECK (organization_id = active_org_id());

CREATE POLICY "Tenant Isolation: Tags" ON "public"."tags" USING (organization_id = active_org_id()) WITH CHECK (organization_id = active_org_id());
