-- 20260103233000_fix_employees_rls.sql

-- Fix RLS on employees to allow viewing all members of the active organization
-- instead of just the user's own record.

DROP POLICY IF EXISTS "Users can view own profile" ON public.employees;
DROP POLICY IF EXISTS "Users can view employees in their organization" ON public.employees;

CREATE POLICY "Users can view employees in their organization"
ON public.employees FOR SELECT
USING (
  organization_id = active_org_id()
);

-- Ensure Insert/Update/Delete are restricted to Admins/Owners (already likely handled but good to reaffirm or leave if existing are fine)
-- We typically rely on "Admins can insert" etc.
-- If we dropped "Users can view own profile", we must ensure they can still view themselves (which active_org_id() covers).
