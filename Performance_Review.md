# Atomic CRM - Performance Review (Final)

## 1. RLS & Tenancy Performance

**The Challenge**: In Multi-Tenant systems, every query filters by `organization_id`. Doing this poorly (e.g., joining 3 tables to find out who you are) kills performance.

**The Solution**: **JWT Claims**.

- Instead of: `WHERE organization_id IN (SELECT org_id FROM employees WHERE user_id = auth.uid())`
- Do this: `WHERE organization_id = (auth.jwt() ->> 'org_id')::bigint`
- **Result**: Zero DB lookups for permission checks. Fast, scalable RLS.

## 2. Indexing Strategy

Generic indexes are insufficient. We need **Tenant-Scoped** indexes.
Most queries will look like: `SELECT * FROM contacts WHERE organization_id = 123 AND email = 'foo@bar.com'`

### Mandatory Indexes

- **Foreign Keys**: Index `organization_id` on ALL tables. (Essential for `ON DELETE CASCADE` performance).
- **Composite Search**:
  - `contacts`: `(organization_id, email)`
  - `deals`: `(organization_id, sales_id)` (for "My Deals")
  - `companies`: `(organization_id, name)`

## 3. JSONB Performance (`custom_data`)

We are using JSONB for custom fields. To make this fast:

- **Index**: `CREATE INDEX idx_deals_custom ON deals USING GIN (organization_id, custom_data);`
- **Querying**: Use the `@>` operator.
  - `SELECT * FROM deals WHERE custom_data @> '{"referral": "partner"}'`
- **Constraint**: GIN indexes are larger and slightly slower to write, but essential for reading/filtering custom data at scale.

## 4. Invitation System

- **Tokenizer**: Ensure `organization_invites.token` has a UNIQUE index for fast lookup during the validation phase.
- **Cleanup**: Schedule a cron job (via pg_cron or Supabase Edge Function) to delete expired invites to keep the table small.
