# Design Specification: User Onboarding & Organization Creation

## 1. Overview

This feature enables new users to create their own isolated workspace (Organization) during the sign-up process. It enforces distinct naming for legal identity ("Name") and display/disambiguation ("Descriptor").

## 2. Database Design

### 2.1 Schema Updates

#### Table: `public.organizations`

| Column | Type | Nullable | Description |
| :--- | :--- | :--- | :--- |
| `id` | bigint | PK | Existing ID |
| `name` | text | NO | Legal/Common Name (e.g., "Mr. Roto Rooter") |
| `descriptor` | text | YES | **[NEW]** Unique descriptor (e.g., "Biloxi Branch") |
| ... | ... | ... | Existing columns |

### 2.2 Triggers & Functions

#### Function: `public.handle_new_user()`

* **Trigger Event**: `AFTER INSERT ON auth.users`
* **Logic update**:
    1. Extract `organization_name` from `raw_user_meta_data`.
    2. Extract `organization_descriptor` from `raw_user_meta_data`.
    3. Insert into `public.organizations`:
        * `name`: `organization_name` (Fallback: "[User]'s Organization")
        * `descriptor`: `organization_descriptor` (Fallback: `organization_name`)
    4. Insert into `public.org_members`:
        * Assign new user as `owner`.

## 3. Frontend Design

### 3.1 Types (`src/types.ts`)

Update `SignUpData` interface:

```typescript
export interface SignUpData {
    email: string;
    password: string;
    first_name: string;
    last_name: string;
    organization_name: string;       // [NEW]
    organization_descriptor: string; // [NEW]
}
```

### 3.2 UI Components

#### `SignupPage.tsx`

* Add **Organization Name** input field (Required).
* Add **Organization Descriptor** input field (Required).
  * *Hint Text*: "Used to identify this workspace in dropdowns. Example: 'Company Name - Branch/Location'"

### 3.3 Data Provider (`dataProvider.ts`)

* Update `signUp` method:
  * Include `organization_name` and `organization_descriptor` in the `options.data` object passed to `supabase.auth.signUp()`.

## 4. Security Considerations

* **Privilege Escalation**: Organization creation is performed by the `SECURITY DEFINER` trigger, isolating the logic from the client. The client can *only* suggest the name/descriptor via metadata.
* **Input Validation**: Standard input validation on the client side. Database text fields will handle storage.

## 5. Migration Plan

1. **SQL Migration**: Add `descriptor` column.
2. **SQL Migration**: Update `handle_new_user` PL/pgSQL function.
3. **Code Update**: Apply frontend changes.
