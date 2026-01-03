import { supabase } from "./supabase";

const STORAGE_KEY = "atomic_crm_active_org_id";

export const getActiveOrgId = (): number | null => {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? parseInt(stored, 10) : null;
};

export const setActiveOrgId = (orgId: number) => {
    localStorage.setItem(STORAGE_KEY, orgId.toString());
    // Inject into Supabase Global Headers for RLS
    // Note: we cast to any because the types might not expose global.headers easily
    (supabase as any).rest.headers['x-organization-id'] = orgId.toString();
    // Also legacy approach just in case
    supabase.global = {
        ...supabase.global,
        headers: {
            ...supabase.global?.headers,
            'x-organization-id': orgId.toString()
        }
    };
};

export const clearActiveOrgId = () => {
    localStorage.removeItem(STORAGE_KEY);
    // Clear header? Maybe keep it or set to invalid.
    delete (supabase as any).rest.headers['x-organization-id'];
};

// Initialize immediately to ensure headers are set before any requests
const stored = localStorage.getItem(STORAGE_KEY);
if (stored) {
    const orgId = parseInt(stored, 10);
    if (!isNaN(orgId)) {
        (supabase as any).rest.headers['x-organization-id'] = orgId.toString();
        supabase.global = {
            ...supabase.global,
            headers: {
                ...supabase.global?.headers,
                'x-organization-id': orgId.toString()
            }
        };
    }
}
