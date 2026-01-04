# User Onboarding & Organization Creation Requirements

## 1. User Experience (UX) Requirements

* **Sign Up Form Enhancement**:
  * **Organization Name** (Required): The legal or common name (e.g., "Mr. Roto Rooter").
  * **Organization Descriptor** (Required): A unique string to distinguish this instance (e.g., "Biloxi Team - 11100 Peach Tree Ln").
    * *Guidance*: Display a hint: "Used to identify this workspace in dropdowns. Example: 'Company Name - Branch/Location'".
* **Feedback**:
  * Clear indication that creating an account also creates a new workspace/organization.
* **Post-Sign Up**:
  * User should land immediately in their new Organization context.
  * The Dashboard and Org Switcher must use the **Descriptor** for display.

## 2. Technical Requirements

### A. Database Schema

* **New Column**: `organizations.descriptor` (Text, Nullable but enforced by UI/Business Logic).
  * If `descriptor` is null, fallback to `name` for display, but strongly encourage uniqueness.
* **Updates**:
  * `20260102194500_multi_tenant_schema.sql` (or new migration) to add the column.
  * Update `handle_new_user` to accept and store `descriptor`.

### B. Data Flow & Security

* **Challenge**: A new user is unauthenticated until the sign-up completes, but `organizations` table usually requires `authenticated` role to insert (via RLS).
* **Proposed Solution (Trigger-based)**:
  * Pass `organization_name` AND `organization_descriptor` inside the `raw_user_meta_data` during `supabase.auth.signUp()`.
  * The `on_auth_user_created` database trigger (running with `SECURITY DEFINER` privileges) will extraction this metadata.
  * The trigger will creation the `organizations` record using the provided name and descriptor.
  * The trigger will create the `org_members` record linking the new user as 'owner'.

### C. Fallback / Edge Cases

* **Missing Metadata**: If metadata is missing, default `descriptor` to `name`.
* **Uniqueness**: `descriptor` does not need unique constraint in DB (collisions possible across tenants), but uniqueness helps the user.

## 3. Implementation Steps (Plan)

1. **Backend (Database)**:
    * Migration: Add `descriptor` column to `public.organizations`.
    * Migration: Update `handle_new_user` function to read `raw_user_meta_data ->> 'organization_descriptor'` and insert it.
2. **Frontend**:
    * Update `types.ts` `SignUpData` interface to include `organization_name` and `organization_descriptor`.
    * Update `SignupPage.tsx` to add the two input fields.
    * Update `dataProvider.ts` -> `signUp` to pass these fields in `options.data`.
    * Update `authProvider.ts` / `OrganizationSwitcher` to prefer `descriptor` over `name` for display.
