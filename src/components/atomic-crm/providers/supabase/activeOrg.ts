import { supabase } from "./supabase";

const STORAGE_KEY = "atomic_crm_active_org_id";

export const getActiveOrgId = (): number | null => {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? parseInt(stored, 10) : null;
};

export const setActiveOrgId = (orgId: number) => {
    localStorage.setItem(STORAGE_KEY, orgId.toString());
};

export const clearActiveOrgId = () => {
    localStorage.removeItem(STORAGE_KEY);
};
