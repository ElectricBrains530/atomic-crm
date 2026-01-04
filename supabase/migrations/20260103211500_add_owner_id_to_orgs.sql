-- 20260103211500_add_owner_id_to_orgs.sql

ALTER TABLE public.organizations 
ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES auth.users(id);
