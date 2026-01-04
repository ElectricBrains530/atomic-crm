-- 20260103150000_fix_active_org_header.sql

CREATE OR REPLACE FUNCTION active_org_id() RETURNS bigint AS $$
DECLARE
    req_org_id text;
    jwt_org_id text;
    header_org_id text;
BEGIN
    -- 1. Try Request Setting (set by RPC or some middleware)
    req_org_id := current_setting('request.org_id', true);
    IF req_org_id IS NOT NULL AND req_org_id <> '' THEN
        RETURN req_org_id::bigint;
    END IF;

    -- 2. Try Request Header (set by Frontend Fetch Interceptor)
    -- PostgREST sets 'request.headers' as a JSON string
    -- effectively: headers ->> 'x-organization-id'
    header_org_id := (current_setting('request.headers', true)::json ->> 'x-organization-id');
    
    IF header_org_id IS NOT NULL AND header_org_id <> '' AND header_org_id <> 'null' THEN
         RETURN header_org_id::bigint;
    END IF;

    -- 3. Try JWT Claim (fallback)
    jwt_org_id := (auth.jwt() -> 'app_metadata' ->> 'active_organization_id');
    IF jwt_org_id IS NOT NULL AND jwt_org_id <> '' THEN
        RETURN jwt_org_id::bigint;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
