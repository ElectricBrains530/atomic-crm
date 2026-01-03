-- Fix Delete Policy on Contacts
DROP POLICY IF EXISTS "Contact Delete Policy" ON "public"."contacts";

CREATE POLICY "Tenant Isolation: Delete Contacts" ON "public"."contacts"
FOR DELETE USING (
  organization_id = active_org_id()
);

-- Retrieve active_org_id source
SELECT pg_get_functiondef('public.active_org_id'::regproc);
