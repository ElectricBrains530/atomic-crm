DO $$
DECLARE
    v_user_id uuid;
    v_org_id bigint;
BEGIN
    -- Get Jane Doe's ID
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'janedoe@atomic.crm';
    
    -- Get Demo Org ID
    SELECT id INTO v_org_id FROM public.organizations LIMIT 1;

    -- Ensure Profile Exists
    INSERT INTO public.user_profiles (user_id, email, full_name)
    VALUES (v_user_id, 'janedoe@atomic.crm', 'Jane Doe')
    ON CONFLICT (user_id) DO NOTHING;

    -- Ensure Membership Exists
    IF v_user_id IS NOT NULL AND v_org_id IS NOT NULL THEN
        INSERT INTO public.org_members (organization_id, user_id, role)
        VALUES (v_org_id, v_user_id, 'owner')
        ON CONFLICT (organization_id, user_id) DO NOTHING;
    END IF;
END $$;
