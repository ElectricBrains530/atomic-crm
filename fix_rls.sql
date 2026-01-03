-- Fix RLS Recursion on org_members

DROP POLICY IF EXISTS "Members can view colleagues" ON "public"."org_members";

CREATE POLICY "Users can view own memberships" ON "public"."org_members"
FOR SELECT USING (
  user_id = auth.uid()
);
