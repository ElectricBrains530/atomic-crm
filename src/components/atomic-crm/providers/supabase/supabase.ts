import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
const STORAGE_KEY = "atomic_crm_active_org_id";

// --- GLOBAL FETCH INTERCEPTOR ---
// This is necessary because 'ra-supabase-core' constructs its own URLs 
// using 'instanceUrl' and bypasses the supabase-js client's internal fetcher
// for some operations (causing 404s if instanceUrl is missing, and missing headers if present).
// This monkey-patch ensures ALL requests to Supabase get the header.

const originalFetch = window.fetch;
window.fetch = async (input, init) => {
  let url = "";
  if (typeof input === "string") {
    url = input;
  } else if (input instanceof URL) {
    url = input.toString();
  } else if (input instanceof Request) {
    url = input.url;
  }

  // Only intercept requests to our Supabase instance
  if (url && url.includes(supabaseUrl)) {
    const orgId = localStorage.getItem(STORAGE_KEY);

    if (orgId) {
      // Prepare init object
      const newInit = { ...init } || {};
      const headers = new Headers(newInit.headers || {});

      // Inject Header
      headers.set("x-organization-id", orgId);
      newInit.headers = headers;

      console.debug(`[GlobalFetch] Intercepted request to ${url}. Injected x-organization-id: ${orgId}`);

      return originalFetch(input, newInit);
    }
  }

  return originalFetch(input, init);
};
// --------------------------------

export const supabase = createClient(supabaseUrl, supabaseKey);
