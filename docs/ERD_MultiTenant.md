# Atomic CRM - Multi-Tenant ERD (Final)

This diagram represents the complete data structure for the Multi-Tenant system, including:

- **Tenancy**: `organization_id` on all secure resources.
- **Hierarchy**: Organizations -> Teams -> Employees (Many-to-Many).
- **Customization**: JSONB `custom_data` and global `settings`.
- **Onboarding**: Invitation system via `organization_invites`.

```mermaid
erDiagram
    %% ==========================================
    %% 1. TENANCY & HIERARCHY
    %% ==========================================
    ORGANIZATIONS ||--o{ TEAMS : "has"
    ORGANIZATIONS ||--o{ EMPLOYEES : "employs"
    ORGANIZATIONS ||--o{ ORGANIZATION_INVITES : "pending invites"

    %% Many-to-Many: Employees can belong to multiple Teams (e.g. HVAC + Plumbing)
    EMPLOYEES ||--|{ EMPLOYEE_TEAMS : "member of"
    TEAMS ||--|{ EMPLOYEE_TEAMS : "has members"

    %% Reporting Line (Self-Referential)
    EMPLOYEES ||--o{ EMPLOYEES : "manages"

    %% ==========================================
    %% 2. DATA OWNERSHIP (RLS SCOPE)
    %% ==========================================
    ORGANIZATIONS ||--o{ COMPANIES : "owns"
    ORGANIZATIONS ||--o{ CONTACTS : "owns"
    ORGANIZATIONS ||--o{ DEALS : "owns"
    ORGANIZATIONS ||--o{ TASKS : "owns"
    ORGANIZATIONS ||--o{ CONTACT_NOTES : "owns"
    ORGANIZATIONS ||--o{ DEAL_NOTES : "owns"

    %% ==========================================
    %% 3. ASSIGNMENTS & RELATIONSHIPS
    %% ==========================================
    %% Account Management
    EMPLOYEES ||--o{ COMPANIES : "account manager"
    EMPLOYEES ||--o{ DEALS : "deal owner"
    EMPLOYEES ||--o{ CONTACTS : "contact owner"
    
    %% Core Relationships
    COMPANIES ||--o{ CONTACTS : "has"
    COMPANIES ||--o{ DEALS : "has"
    
    CONTACTS ||--o{ TASKS : "activity"
    DEALS }|..|{ CONTACTS : "involves (via ids array)"

    %% ==========================================
    %% 4. TABLE DEFINITIONS
    %% ==========================================
    ORGANIZATIONS {
        bigint id PK
        text name
        text plan "tier: free, pro, enterprise"
        jsonb settings "Active Stages, Custom Field Labels"
        timestamp created_at
    }

    ORGANIZATION_INVITES {
        bigint id PK
        bigint organization_id FK
        text email
        text role "owner, admin, member"
        uuid token "Secure unique token"
        timestamp expires_at
        text status "pending, accepted, expired"
    }

    TEAMS {
        bigint id PK
        bigint organization_id FK
        text name "NYC Office, HVAC Team"
        text address
    }

    EMPLOYEES {
        bigint id PK
        uuid user_id FK "auth.users (Global Identity)"
        bigint organization_id FK
        bigint manager_id FK "Reporting line"
        text role "System Role"
        text[] skills "Cached skill tags"
        text job_title
    }

    EMPLOYEE_TEAMS {
        bigint employee_id FK
        bigint team_id FK
        text role "Team Lead / Member"
    }

    COMPANIES {
        bigint id PK
        bigint organization_id FK
        bigint sales_id FK "Account Manager (Employee)"
        text name
        text sector
        jsonb custom_data "User-defined field values"
    }

    CONTACTS {
        bigint id PK
        bigint organization_id FK
        bigint sales_id FK "Owner (Employee)"
        bigint company_id FK
        jsonb email_jsonb "List of emails"
        jsonb custom_data "User-defined field values"
    }

    DEALS {
        bigint id PK
        bigint organization_id FK
        bigint sales_id FK "Deal Owner (Employee)"
        bigint company_id FK
        bigint[] contact_ids "Participants"
        text name
        bigint amount
        text stage "Must match Organization Settings"
        smallint index "Kanban Sort Order"
        jsonb custom_data "User-defined field values"
    }

    TASKS {
        bigint id PK
        bigint organization_id FK
        bigint contact_id FK
        bigint sales_id FK "Assigned To"
        text type "Call, Email, Meeting"
        text content
        timestamp due_date
    }
```
