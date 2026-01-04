-- Create or Update Dev User via PL/SQL to avoid constraint issues
DO $$
DECLARE
    v_user_id uuid;
    v_org_id bigint;
BEGIN
    -- Check if user exists
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'dev@electricbrains.ai';

    IF v_user_id IS NULL THEN
        -- Create User
        v_user_id := gen_random_uuid();
        INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
        VALUES (
            '00000000-0000-0000-0000-000000000000',
            v_user_id,
            'authenticated',
            'authenticated',
            'dev@electricbrains.ai',
            crypt('password', gen_salt('bf')),
            now(),
            NULL,
            now(),
            '{"provider":"email","providers":["email"]}',
            '{"first_name": "Dev", "last_name": "User"}',
            now(),
            now(),
            '',
            '',
            '',
            ''
        );
    ELSE
        -- Update Password
        UPDATE auth.users
        SET encrypted_password = crypt('password', gen_salt('bf')),
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    -- Backfill Membership
    SELECT id INTO v_org_id FROM public.organizations LIMIT 1;
    
    INSERT INTO public.user_profiles (user_id, email, full_name)
    VALUES (v_user_id, 'dev@electricbrains.ai', 'Dev User')
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO public.org_members (organization_id, user_id, role)
    VALUES (v_org_id, v_user_id, 'admin')
    ON CONFLICT (organization_id, user_id) DO NOTHING;
END $$;
