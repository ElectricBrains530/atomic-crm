-- 20260103160000_seed_deal_stages.sql

-- 1. Update the Trigger Function to Seed Stages for NEW Users
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

  -- 7. Seed Default Deal Stages (NEW)
  INSERT INTO "public"."deal_stages" (organization_id, label, probability, sort_order)
  VALUES
      (new_org_id, 'Opportunity', 10, 1),
      (new_org_id, 'Proposal Sent', 30, 2),
      (new_org_id, 'In Negotiation', 70, 3),
      (new_org_id, 'Won', 100, 4),
      (new_org_id, 'Lost', 0, 5),
      (new_org_id, 'Delayed', 0, 6);

  RETURN new;
END;
$$;

-- 2. Backfill Existing Organizations
DO $$
DECLARE
    org RECORD;
BEGIN
    FOR org IN SELECT id, name FROM public.organizations LOOP
        -- Check if stages exist for this org
        IF NOT EXISTS (SELECT 1 FROM public.deal_stages WHERE organization_id = org.id) THEN
            RAISE NOTICE 'Seeding stages for Organization: % (ID: %)', org.name, org.id;
            
            INSERT INTO "public"."deal_stages" (organization_id, label, probability, sort_order)
            VALUES
                (org.id, 'Opportunity', 10, 1),
                (org.id, 'Proposal Sent', 30, 2),
                (org.id, 'In Negotiation', 70, 3),
                (org.id, 'Won', 100, 4),
                (org.id, 'Lost', 0, 5),
                (org.id, 'Delayed', 0, 6);
        END IF;
    END LOOP;
END $$;
