-- 20260103230000_link_employees_members.sql

-- Add FK from employees to org_members to enable PostgREST joins
-- This allows us to select employees and join their member role in one query.

ALTER TABLE public.employees
DROP CONSTRAINT IF EXISTS employees_org_member_fkey;

ALTER TABLE public.employees
ADD CONSTRAINT employees_org_member_fkey
FOREIGN KEY (organization_id, user_id)
REFERENCES public.org_members (organization_id, user_id)
ON DELETE CASCADE;
