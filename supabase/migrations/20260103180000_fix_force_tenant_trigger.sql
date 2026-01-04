-- 20260103180000_fix_force_tenant_trigger.sql

CREATE OR REPLACE FUNCTION public.force_tenant_id()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- If organization_id is ALREADY provided (e.g. by Trusted Function), keep it.
  IF NEW.organization_id IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- Otherwise, try to set it from the active context.
  NEW.organization_id := active_org_id();

  -- If still null, raise exception
  IF NEW.organization_id IS NULL THEN
     RAISE EXCEPTION 'Cannot insert record without an active Organization Context.';
  END IF;

  RETURN NEW;
END;
$$;
