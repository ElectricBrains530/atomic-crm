/* eslint-disable no-var */
/* eslint-disable @typescript-eslint/no-namespace */
import type { AuthProvider } from "ra-core";
import { supabaseAuthProvider } from "ra-supabase-core";

import { canAccess } from "../commons/canAccess";
import { getActiveOrgId, setActiveOrgId } from "./activeOrg";
import { supabase } from "./supabase";

// Define the shape of our new Member/Profile hybrid
type OrgMemberProfile = {
  id: number; // org_member id
  organization_id: number;
  user_id: string;
  role: string;
  status: string;
  user_profiles: {
    full_name: string;
    avatar_url: string | null;
  } | null;
  organizations: {
    name: string;
    plan: string;
  } | null;
};

const baseAuthProvider = supabaseAuthProvider(supabase, {
  getIdentity: async () => {
    const { activeMember, allMemberships } = await getActiveMembership();

    if (activeMember == null) {
      throw new Error("No active membership found");
    }

    const profile = activeMember.user_profiles || { full_name: "Unknown", avatar_url: null };

    return {
      id: activeMember.id,
      fullName: profile.full_name,
      avatar: profile.avatar_url ?? undefined,
      activeOrgId: activeMember.organization_id,
      availableOrgs: allMemberships.map(m => ({
        id: m.organization_id,
        name: m.organizations?.name,
        plan: m.organizations?.plan,
        role: m.role
      }))
    };
  },
});

export async function getIsInitialized() {
  if (getIsInitialized._is_initialized_cache == null) {
    const { data } = await supabase.from("init_state").select("is_initialized");
    getIsInitialized._is_initialized_cache = data?.at(0)?.is_initialized > 0;
  }
  return getIsInitialized._is_initialized_cache;
}

export namespace getIsInitialized {
  export var _is_initialized_cache: boolean | null = null;
}

export const authProvider: AuthProvider = {
  ...baseAuthProvider,
  login: async (params) => {
    const result = await baseAuthProvider.login(params);
    // clear cached member
    cachedMember = undefined;
    return result;
  },
  checkAuth: async (params) => {
    // Whitelist public pages
    const path = window.location.pathname;
    const hash = window.location.hash;
    if (
      path === "/set-password" || hash.includes("#/set-password") ||
      path === "/forgot-password" || hash.includes("#/forgot-password") ||
      path === "/sign-up" || hash.includes("#/sign-up")
    ) {
      return;
    }

    const isInitialized = await getIsInitialized();
    if (!isInitialized) {
      await supabase.auth.signOut();
      throw { redirectTo: "/sign-up", message: false };
    }

    // Standard check (validates session expiry)
    await baseAuthProvider.checkAuth(params);

    // Ensure we have an active org context
    const { activeMember } = await getActiveMembership();
    if (!activeMember) {
      return;
    }
  },
  canAccess: async (params) => {
    const isInitialized = await getIsInitialized();
    if (!isInitialized) return false;

    const { activeMember } = await getActiveMembership();
    if (activeMember == null) return false;

    // Compute access rights from the role
    // Map 'owner'/'admin' to administrator privileges
    const administrator = activeMember.role === 'owner' || activeMember.role === 'admin';
    const role = administrator ? "admin" : "user";
    return canAccess(role, params);
  },
  getAuthorizationDetails(authorizationId: string) {
    return supabase.auth.oauth.getAuthorizationDetails(authorizationId);
  },
  approveAuthorization(authorizationId: string) {
    return supabase.auth.oauth.approveAuthorization(authorizationId);
  },
  denyAuthorization(authorizationId: string) {
    return supabase.auth.oauth.denyAuthorization(authorizationId);
  },
};

let cachedMember: OrgMemberProfile | undefined;
let cachedMemberships: OrgMemberProfile[] | undefined;

// This is the core logic for Context Switching
const getActiveMembership = async (): Promise<{ activeMember: OrgMemberProfile | undefined, allMemberships: OrgMemberProfile[] }> => {
  // We don't use simple caching here because we want to allow switching
  // But for performance within a render cycle, maybe? 
  // For now, let's relie on Supabase client caching of session.
  // Actually, we should cache the memberships to avoid DB hit on every render.
  if (cachedMember && cachedMemberships) {
    return { activeMember: cachedMember, allMemberships: cachedMemberships };
  }

  const { data: dataSession, error: errorSession } = await supabase.auth.getSession();
  if (dataSession?.session?.user == null || errorSession) {
    return { activeMember: undefined, allMemberships: [] };
  }

  const userId = dataSession.session.user.id;

  // Fetch ALL memberships for this user
  const { data: memberships, error } = await supabase
    .from("org_members")
    .select("*, user_profiles(full_name, avatar_url), organizations(name, plan)")
    .eq("user_id", userId);

  if (error || !memberships || memberships.length === 0) {
    console.warn("User has no Organization Memberships.");
    return { activeMember: undefined, allMemberships: [] };
  }

  // Determine Active Org
  const storedOrgId = getActiveOrgId();
  let activeMember = memberships.find(m => m.organization_id === storedOrgId);

  // Fallback to first membership if stored ID is invalid/missing
  if (!activeMember) {
    activeMember = memberships[0];
    setActiveOrgId(activeMember.organization_id); // Save default and Set Header
  } else {
    // Ensure header is set even if found in storage
    setActiveOrgId(activeMember.organization_id);
  }

  cachedMember = activeMember as unknown as OrgMemberProfile;
  cachedMemberships = memberships as unknown as OrgMemberProfile[];

  return { activeMember: cachedMember, allMemberships: cachedMemberships };
};
