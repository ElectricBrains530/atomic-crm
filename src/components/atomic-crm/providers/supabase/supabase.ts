import { createClient } from "@supabase/supabase-js";

const client = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
);

const STORAGE_KEY = "atomic_crm_active_org_id";

export const supabase = new Proxy(client, {
  get(target, prop, receiver) {
    // Intercept 'from' to inject header
    if (prop === 'from') {
      return (table: string) => {
        const builder = target.from(table);
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) {
          if (typeof (builder as any).setHeader === 'function') {
            (builder as any).setHeader('x-organization-id', stored);
          }
        }
        return builder;
      }
    }
    // Intercept 'rpc' to inject header
    if (prop === 'rpc') {
      return (fn: string, args: any, options: any) => {
        const builder = target.rpc(fn, args, options);
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored && typeof (builder as any).setHeader === 'function') {
          (builder as any).setHeader('x-organization-id', stored);
        }
        return builder;
      }
    }
    return Reflect.get(target, prop, receiver);
  }
});
