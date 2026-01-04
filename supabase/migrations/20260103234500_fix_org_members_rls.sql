-- 20260103234500_fix_org_members_rls.sql

-- Fix RLS on org_members to allow viewing all members of organizations the user belongs to.
-- This is required for the employees join (to see roles of other users).

DROP POLICY IF EXISTS "Users can view own memberships" ON public.org_members;

CREATE POLICY "Users can view members of their organizations"
ON public.org_members FOR SELECT
USING (
  organization_id IN (
    SELECT organization_id FROM public.org_members WHERE user_id = auth.uid()
  )
);
