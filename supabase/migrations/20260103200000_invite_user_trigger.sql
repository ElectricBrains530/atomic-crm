-- 20260103200000_invite_user_trigger.sql

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  org_id bigint;
  meta_org_id bigint;
BEGIN
  -- Check if an organization_id was passed in metadata (Invite Flow)
  -- We cast to text first, then bigint to be safe with JSONB extraction
  meta_org_id := (new.raw_user_meta_data->>'organization_id')::bigint;

  IF meta_org_id IS NOT NULL THEN
    -- JOIN EXISTING ORGANIZATION
    org_id := meta_org_id;
    
    -- Add user as member to existing org
    INSERT INTO public.org_members (user_id, organization_id, role)
    VALUES (new.id, org_id, 'member');

  ELSE
    -- CREATE NEW ORGANIZATION (Standard Signup)
    INSERT INTO public.organizations (name, descriptor, owner_id)
    VALUES (
      COALESCE(new.raw_user_meta_data->>'organization_name', 'My Organization'),
      COALESCE(new.raw_user_meta_data->>'organization_descriptor', 'Organization'),
      new.id
    )
    RETURNING id INTO org_id;

    -- Add user as owner to new org
    INSERT INTO public.org_members (user_id, organization_id, role)
    VALUES (new.id, org_id, 'owner');
    
    -- Seed default deal stages for the new organization
    INSERT INTO public.deal_stages (organization_id, label, probability, sort_order)
    VALUES 
      (org_id, 'Opportunity', 10, 1),
      (org_id, 'Proposal', 30, 2),
      (org_id, 'In Negotiation', 50, 3),
      (org_id, 'Won', 100, 4),
      (org_id, 'Lost', 0, 5),
      (org_id, 'Delayed', 0, 6);
  END IF;

  -- Create Sales Profile (Agent) linked to the Organization
  -- Note: We rely on force_tenant_id trigger? No, we set org_id explicitly.
  INSERT INTO public.sales (
    user_id, 
    organization_id, 
    first_name, 
    last_name, 
    email
  )
  VALUES (
    new.id, 
    org_id, 
    COALESCE(new.raw_user_meta_data->>'first_name', ''), 
    COALESCE(new.raw_user_meta_data->>'last_name', ''), 
    new.email
  );

  RETURN new;
END;
$$;
