# Atomic CRM - Entity Relationship Diagram

```mermaid
erDiagram
    %% Core Entities
    SALES ||--o{ COMPANIES : manages
    SALES ||--o{ CONTACTS : manages
    SALES ||--o{ DEALS : manages

    COMPANIES ||--o{ CONTACTS : has
    COMPANIES ||--o{ DEALS : has

    %% Main Relations
    CONTACTS ||--o{ TASKS : "has activity"
    CONTACTS ||--o{ CONTACT_NOTES : "has notes"
    
    DEALS ||--o{ DEAL_NOTES : "has notes"
    DEALS }|..|{ CONTACTS : "involves (via array)"

    %% Definitions
    SALES {
        bigint id PK
        uuid user_id FK "auth.users"
        text first_name
        text last_name
        text email
        boolean administrator
    }

    COMPANIES {
        bigint id PK
        text name
        text sector
        smallint size
        bigint sales_id FK
        text website
        text linkedin_url
        text phone_number
        text address
        text city
        text country
    }

    CONTACTS {
        bigint id PK
        text first_name
        text last_name
        jsonb email_jsonb
        bigint company_id FK
        bigint sales_id FK
        text title
        text gender
        text status
        bigint[] tags
    }

    DEALS {
        bigint id PK
        text name
        bigint amount
        text stage
        bigint company_id FK
        bigint sales_id FK
        bigint[] contact_ids "Ref to Contacts"
        timestamp expected_closing_date
        smallint index "Kanban Order"
    }

    TASKS {
        bigint id PK
        bigint contact_id FK
        text type "Email, Call, Meeting"
        text text
        timestamp due_date
        timestamp done_date
    }

    CONTACT_NOTES {
        bigint id PK
        bigint contact_id FK
        bigint sales_id FK
        text text
        timestamp date
    }

    DEAL_NOTES {
        bigint id PK
        bigint deal_id FK
        bigint sales_id FK
        text text
        timestamp date
    }

    TAGS {
        bigint id PK
        text name
        text color
    }
```

## Schema Notes

- **Sales**: Links to the Supabase Auth user via `user_id`.
- **Contacts**: Emails are stored in `email_jsonb` allowing multiple emails per contact.
- **Deals**: Linked to multiple contacts via the `contact_ids` array column (logical many-to-many).
- **Security**: All tables have Row Level Security (RLS) enabled, generally restricting access to authenticated users.
