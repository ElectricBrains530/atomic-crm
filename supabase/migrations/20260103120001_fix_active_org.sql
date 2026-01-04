-- Update active_org_id to read properly from request headers
CREATE OR REPLACE FUNCTION public.active_org_id()
RETURNS bigint
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $$
DECLARE
    header_org_id text;
    jwt_org_id text;
BEGIN
    -- 1. Try Custom Header (x-organization-id) from Frontend
    -- PostgREST exposes headers in this setting
    header_org_id := current_setting('request.headers', true)::json ->> 'x-organization-id';
    
    -- Validate and Return
    IF header_org_id IS NOT NULL AND header_org_id ~ '^[0-9]+$' THEN
        RETURN header_org_id::bigint;
    END IF;

    -- 2. Try JWT Claim (Fallback)
    jwt_org_id := (auth.jwt() -> 'app_metadata' ->> 'active_organization_id');
    IF jwt_org_id IS NOT NULL AND jwt_org_id <> '' THEN
        RETURN jwt_org_id::bigint;
    END IF;

    -- 3. Fallback: If ZERO context, return NULL
    RETURN NULL;
END;
$$;
