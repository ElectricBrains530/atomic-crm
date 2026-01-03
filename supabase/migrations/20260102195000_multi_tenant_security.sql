-- 20260102195000_multi_tenant_security.sql

-- 1. Global Context Function (The "Brain" of RLS)
CREATE OR REPLACE FUNCTION active_org_id() RETURNS bigint AS $$
DECLARE
    -- Check for request-scoped config (fastest)
    req_org_id text;
    jwt_org_id text;
BEGIN
    -- 1. Try Request Setting (set by API/Middleware)
    req_org_id := current_setting('request.org_id', true);
    IF req_org_id IS NOT NULL AND req_org_id <> '' THEN
        RETURN req_org_id::bigint;
    END IF;

    -- 2. Try JWT Claim (set by Auth Trigger/Hook)
    jwt_org_id := (auth.jwt() -> 'app_metadata' ->> 'active_organization_id');
    IF jwt_org_id IS NOT NULL AND jwt_org_id <> '' THEN
        RETURN jwt_org_id::bigint;
    END IF;

    -- 3. Fallback: If ZERO context, return NULL (Safe default -> Deny All)
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. "Force Tenant" Trigger (The "Muscle" of Security)
-- Prevents clients from spoofing the organization level 
CREATE OR REPLACE FUNCTION force_tenant_id() RETURNS TRIGGER AS $$
BEGIN
    -- Force the org_id to match the active context
    -- Exception: If executed by Database Owner/Superuser, allow manual override (useful for admin scripts)
    -- BUT for standard RLS usage, valid active_org_id() is mandatory.
    
    IF active_org_id() IS NOT NULL THEN
        NEW.organization_id := active_org_id();
    ELSIF NEW.organization_id IS NULL THEN
         RAISE EXCEPTION 'Cannot insert record without an active Organization Context.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply Trigger to ALL Tenant Tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT unnest(ARRAY['companies', 'contacts', 'deals', 'tasks', 'deal_stages', 'teams'])
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_force_tenant ON %I', t);
        EXECUTE format('CREATE TRIGGER trg_force_tenant BEFORE INSERT OR UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION force_tenant_id()', t);
    END LOOP;
END $$;

-- 3. Enable RLS on All Tables
ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."org_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."teams" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."team_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."deal_stages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."organization_invites" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."companies" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."contacts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."deals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- A. Organizations (Members can read their own org)
CREATE POLICY "Members can view their own organization" ON "public"."organizations"
FOR SELECT USING (
  id IN (SELECT organization_id FROM public.org_members WHERE user_id = auth.uid())
);

-- B. Org Members (Members can view their colleagues)
CREATE POLICY "Members can view colleagues" ON "public"."org_members"
FOR SELECT USING (
  organization_id IN (SELECT organization_id FROM public.org_members WHERE user_id = auth.uid())
);

-- C. Operational Tables (Isolation via active_org_id)
-- Using the FUNCTION directly is cleaner and follows the agreed design pattern.
CREATE POLICY "Tenant Isolation: Companies" ON "public"."companies"
USING (organization_id = active_org_id())
WITH CHECK (organization_id = active_org_id());

CREATE POLICY "Tenant Isolation: Contacts" ON "public"."contacts"
USING (organization_id = active_org_id())
WITH CHECK (organization_id = active_org_id());

CREATE POLICY "Tenant Isolation: Deals" ON "public"."deals"
USING (organization_id = active_org_id())
WITH CHECK (organization_id = active_org_id());

CREATE POLICY "Tenant Isolation: Tasks" ON "public"."tasks"
USING (organization_id = active_org_id())
WITH CHECK (organization_id = active_org_id());

CREATE POLICY "Tenant Isolation: Teams" ON "public"."teams"
USING (organization_id = active_org_id())
WITH CHECK (organization_id = active_org_id());

CREATE POLICY "Tenant Isolation: Stages" ON "public"."deal_stages"
USING (organization_id = active_org_id())
WITH CHECK (organization_id = active_org_id());

-- 5. RPC: Set Active Organization (For Context Switching)
-- Should be called by Frontend Session Logic
CREATE OR REPLACE FUNCTION set_request_org_id(org_id bigint) RETURNS void AS $$
BEGIN
    -- Verify User is Member
    IF NOT EXISTS (SELECT 1 FROM public.org_members WHERE user_id = auth.uid() AND organization_id = org_id) THEN
        RAISE EXCEPTION 'Access Denied: You are not a member of this Organization.';
    END IF;

    -- Set Request Config
    PERFORM set_config('request.org_id', org_id::text, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
