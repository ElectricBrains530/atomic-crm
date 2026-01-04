# Atomic CRM - Implementation Master Plan

This document outlines the strategy for transforming the current Single-Tenant app into a robust Multi-Tenant SaaS.

## 1. Schema Architecture

### 1.1 Multi-Tenancy (Data Isolation)

- **Concept**: Shared Database, Tenant-Isolated Rows.
- **Requirement**: Every "secure" table MUST have an `organization_id` column.
- **Tables Affected**: `companies`, `contacts`, `deals`, `tasks`, `notes`, `files`.
- **Migration**:
    1. Create `organizations` table.
    2. Create default "Demo Org".
    3. Add `organization_id` column to all tables (nullable first).
    4. Backfill existing data to "Demo Org".
    5. Make `organization_id` NOT NULL.
    6. Enable RLS policies.

### 1.2 Hierarchy (Organization -> Teams -> Employees)

- **Employees**: Replaces simple "users". Links `auth.users` to `organizations`.
  - Includes `manager_id` for reporting lines.
- **Teams**: Represents Locations or Departments (e.g., "West Coast", "HVAC").
- **Employee_Teams**: Many-to-Many junction table allowing an employee to be in multiple teams.

### 1.3 Invitations

- **Table**: `organization_invites`
- **Flow**:
  - Admin creates invite (Email + Role).
  - System generates magic link with `token`.
  - User clicks link -> mapped to `organization_id` in `employees` table.

## 2. Customization Feature

### 2.1 Configuration

- **Storage**: `organizations.settings` (JSONB).
- **Content**:
  - `stages`: Active Pipeline Stages + Probabilities.
  - `custom_fields`: Labels and Types for custom data columns.

### 2.2 Dynamic Fields

- **Storage**: `custom_data` (JSONB) on `companies` and `deals`.
- **Frontend**:
  - App loads `settings` on startup.
  - Components (Lists/Forms) read `settings` to dynamically render "Label" for "Custom Field 1".

## 3. Core Feature Requirements

### 3.1 Company "Deals" Tab

- **UI**: Added to Company Show/Edit page.
- **Data**: Fetch `deals` where `company_id = current_id`.

### 3.2 Auto-Assignment

- **Logic**: When creating a Deal from a Company:
  - Set `deal.company_id = company.id`
  - Set `deal.sales_id` (Owner) = `company.sales_id` (Account Manager).

## 4. Security (RLS) Strategy

- **Policy Pattern**:

    ```sql
    -- Standard Policy for all tables
    CREATE POLICY tenant_isolation ON table_name
    USING (organization_id = auth.jwt() -> 'app_metadata' -> 'organization_id');
    ```

- **Optimization**: Store the active `organization_id` in the User's JWT at login to avoid expensive subqueries against the `employees` table on every request.
