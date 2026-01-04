-- 20260104000000_safe_org_members_policy.sql

-- Implement SAFE visibility for org_members.
-- 1. Users can see their own memberships (to switch orgs).
-- 2. Users can see ALL members of the currently active organization (to see Sales Team).
-- We use active_org_id() because it's a header-based check and avoids recursion.

DROP POLICY IF EXISTS "Users can view own memberships" ON public.org_members;
DROP POLICY IF EXISTS "Users can view members of their organizations" ON public.org_members;

CREATE POLICY "Users can view relevant members"
ON public.org_members FOR SELECT
USING (
  user_id = auth.uid()
  OR
  organization_id = active_org_id()
);
