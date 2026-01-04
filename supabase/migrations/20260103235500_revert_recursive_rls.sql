-- 20260103235500_revert_recursive_rls.sql

-- EMERGENCY REVERT
-- The previous policy caused infinite recursion by querying org_members within the org_members policy.
-- We revert to "View Own Memberships" to restore access immediately.

DROP POLICY IF EXISTS "Users can view members of their organizations" ON public.org_members;

CREATE POLICY "Users can view own memberships"
ON public.org_members FOR SELECT
USING (
  user_id = auth.uid()
);
