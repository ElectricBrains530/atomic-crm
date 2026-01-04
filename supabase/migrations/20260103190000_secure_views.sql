-- 20260103190000_secure_views.sql

-- 1. Secure contacts_summary
-- Setting security_invoker = true forces the view to respect the RLS policies of the underlying tables (contacts, tasks, etc)
ALTER VIEW "public"."contacts_summary" SET (security_invoker = true);

-- 2. Secure companies_summary
ALTER VIEW "public"."companies_summary" SET (security_invoker = true);

-- 3. Verify organization_id presence (Optional, but good for filtering if needed)
-- Views usually inherit columns, so if contacts has org_id, summary should too if selected * or explicitly.
-- Let's check if we need to recreate them to include org_id?
-- Usually these summaries aggregate. 
-- The "Security Invoker" is the key fix.
