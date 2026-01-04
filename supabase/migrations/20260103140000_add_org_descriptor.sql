-- Add descriptor column to organizations
ALTER TABLE "public"."organizations" ADD COLUMN "descriptor" text;

-- Update handle_new_user to use organization_name and descriptor
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  sales_count int;
  new_org_id bigint;
  user_full_name text;
  org_name text;
  org_descriptor text;
BEGIN
  -- 1. Check sales count (legacy logic)
  SELECT count(id) INTO sales_count FROM public.sales;

  -- 2. Insert into public.sales (Legacy Profile)
  INSERT INTO public.sales (first_name, last_name, email, user_id, administrator)
  VALUES (
    new.raw_user_meta_data ->> 'first_name', 
    new.raw_user_meta_data ->> 'last_name', 
    new.email, 
    new.id, 
    CASE WHEN sales_count > 0 THEN FALSE ELSE TRUE END
  );

  -- 3. Insert into public.user_profiles (New Profile)
  user_full_name := (new.raw_user_meta_data ->> 'first_name') || ' ' || (new.raw_user_meta_data ->> 'last_name');
  
  INSERT INTO public.user_profiles (user_id, email, full_name)
  VALUES (new.id, new.email, user_full_name)
  ON CONFLICT (user_id) DO NOTHING;

  -- 4. Determine Organization Details
  org_name := new.raw_user_meta_data ->> 'organization_name';
  org_descriptor := new.raw_user_meta_data ->> 'organization_descriptor';

  -- Fallbacks
  IF org_name IS NULL OR org_name = '' THEN
    org_name := user_full_name || '''s Organization';
  END IF;

  IF org_descriptor IS NULL OR org_descriptor = '' THEN
    org_descriptor := org_name;
  END IF;

  -- 5. Create Organization
  INSERT INTO public.organizations (name, descriptor, plan)
  VALUES (org_name, org_descriptor, 'free')
  RETURNING id INTO new_org_id;

  -- 6. Add user as Owner
  INSERT INTO public.org_members (organization_id, user_id, role)
  VALUES (new_org_id, new.id, 'owner');

  RETURN new;
END;
$$;
