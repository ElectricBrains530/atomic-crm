-- Clean up permissive policies that override Tenant Isolation

-- Contacts
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."contacts";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."contacts";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."contacts";
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON "public"."contacts"; -- In case it exists

-- Companies
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."companies";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."companies";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."companies";

-- Deals
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "public"."deals";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "public"."deals";
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON "public"."deals";

-- Ensure Tenant Isolation policies are the ONLY ones active (Check)
-- We assume "Tenant Isolation: TableName" policies already exist from previous migration.
