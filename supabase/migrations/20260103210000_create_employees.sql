-- 20260103210000_create_employees.sql

-- 1. Create Employees Table (Replaeing Sales)
CREATE TABLE IF NOT EXISTS public.employees (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id bigint REFERENCES public.organizations(id) ON DELETE CASCADE,
    first_name text,
    last_name text,
    email text,
    avatar text,
    status text DEFAULT 'active', -- 'active', 'disabled', 'invited'?
    job_title text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Add RLS Policies (Standard Multi-Tenant)
CREATE POLICY "Users can view employees in their organization"
    ON public.employees FOR SELECT
    USING (organization_id = active_org_id());

CREATE POLICY "Users can update their own employee record"
    ON public.employees FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Admins can update employees in their organization"
    ON public.employees FOR UPDATE
    USING (
        organization_id = active_org_id() AND
        EXISTS (
            SELECT 1 FROM public.org_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Admins can insert employees"
    ON public.employees FOR INSERT
    WITH CHECK (
        organization_id = active_org_id() AND
        EXISTS (
            SELECT 1 FROM public.org_members 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );
-- Also allow System/Trigger to insert (bypass RLS via Security Definer functions)


-- 2. Update handle_new_user Trigger
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
    
    -- Seed default deal stages
    INSERT INTO public.deal_stages (organization_id, label, probability, sort_order)
    VALUES 
      (org_id, 'Opportunity', 10, 1),
      (org_id, 'Proposal', 30, 2),
      (org_id, 'In Negotiation', 50, 3),
      (org_id, 'Won', 100, 4),
      (org_id, 'Lost', 0, 5),
      (org_id, 'Delayed', 0, 6);
  END IF;

  -- Insert into EMPLOYEES (New Standard)
  -- Note: We deprecate creating 'sales' records.
  INSERT INTO public.employees (
    user_id, 
    organization_id, 
    first_name, 
    last_name, 
    email,
    status
  )
  VALUES (
    new.id, 
    org_id, 
    COALESCE(new.raw_user_meta_data->>'first_name', ''), 
    COALESCE(new.raw_user_meta_data->>'last_name', ''), 
    new.email,
    'active'
  );

  RETURN new;
END;
$$;

-- 3. Backfill Employees from Sales (Migration)
INSERT INTO public.employees (user_id, organization_id, first_name, last_name, email, status)
SELECT 
    s.user_id, 
    om.organization_id, 
    s.first_name, 
    s.last_name, 
    s.email,
    CASE WHEN s.disabled THEN 'disabled' ELSE 'active' END
FROM public.sales s
JOIN public.org_members om ON s.user_id = om.user_id
WHERE NOT EXISTS (SELECT 1 FROM public.employees e WHERE e.user_id = s.user_id);
-- Note: 'sales' table might have missing organization_id but org_members is reliable.

