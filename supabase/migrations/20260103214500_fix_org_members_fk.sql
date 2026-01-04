-- 20260103214500_fix_org_members_fk.sql

-- Repoint org_members.user_id to auth.users to decouple from legacy user_profiles
ALTER TABLE public.org_members
DROP CONSTRAINT IF EXISTS org_members_user_id_fkey;

ALTER TABLE public.org_members
ADD CONSTRAINT org_members_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
