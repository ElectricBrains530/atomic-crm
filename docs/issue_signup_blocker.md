# Issue: Sign Up Page Blocked by Initialization Logic

## 1. Problem Description

The `SignupPage` component currently enforces a "Single-user Onboarding" flow. It checks if the application is "initialized" and, if so, redirects any visitor to the `/login` page. This prevents the creation of additional tenants (users/organizations) via the UI, which is necessary for validating the multi-tenancy requirements.

## 2. Technical Root Cause

### A. `src/components/atomic-crm/providers/supabase/authProvider.ts`

The function `getIsInitialized` queries a database view `init_state`:

```typescript
export async function getIsInitialized() {
  if (getIsInitialized._is_initialized_cache == null) {
    const { data } = await supabase.from("init_state").select("is_initialized");
    getIsInitialized._is_initialized_cache = data?.at(0)?.is_initialized > 0;
  }
  return getIsInitialized._is_initialized_cache;
}
```

The `init_state` view counts the number of records in `public.sales`. Since users already exist (Jane Doe, Dev User), this returns `true`.

### B. `src/components/atomic-crm/login/SignupPage.tsx`

The component uses this check to guard the route:

```tsx
  // For the moment, we only allow one user to sign up. Other users must be created by the administrator.
  if (isInitialized) {
    return <Navigate to="/login" />;
  }
```

## 3. Impact

* **Validation Blocked**: We cannot validate the "Fantastic Fox" and "Moo Cow" scenarios via the UI because the Sign Up page is inaccessible.
* **Feature Limitation**: The application currently does not support self-service sign-ups for multiple tenants, which contradicts the goal of a multi-tenant SaaS CRM.

## 4. Proposed Solution

To enable multi-tenancy validation and functional public sign-ups:

1. **Remove the Redirect**: Modify `SignupPage.tsx` to remove the `isInitialized` check (or make it conditional on a "disable_public_signup" flag).
2. **Update Logic**: Allow the sign-up form to function regardless of existing users.
