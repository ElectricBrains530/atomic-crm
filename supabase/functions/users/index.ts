import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";
import { corsHeaders, createErrorResponse } from "../_shared/utils.ts";

// Helper to get Employee by ID
async function getEmployee(user_id: string) {
  const { data, error } = await supabaseAdmin
    .from("employees")
    .select("*")
    .eq("user_id", user_id)
    .single();

  if (error) console.error("getEmployee error", error);
  return data;
}

// Helper to update Employee
async function updateEmployee(user_id: string, updates: any) {
  const { data, error } = await supabaseAdmin
    .from("employees")
    .update(updates)
    .eq("user_id", user_id)
    .select("*")
    .single();

  if (error) {
    console.error("updateEmployee error", error);
    throw error;
  }
  return data;
}

// Helper to update Org Member Role
async function updateMemberRole(user_id: string, organization_id: number, isAdmin: boolean) {
  const role = isAdmin ? 'admin' : 'member';
  // Note: 'owner' should probably remain owner, but for now we toggle admin/member.

  const { error } = await supabaseAdmin
    .from("org_members")
    .update({ role })
    .eq("user_id", user_id)
    .eq("organization_id", organization_id);

  if (error) console.error("updateMemberRole error", error);
}

async function inviteUser(req: Request, currentMember: any) {
  const { email, password = "password", first_name, last_name, disabled, administrator } = await req.json();

  // Authorization Check
  if (currentMember.role !== 'owner' && currentMember.role !== 'admin') {
    return createErrorResponse(401, "Not Authorized: You must be an admin to invite users.");
  }

  console.log(`[InviteUser] Inviting ${email} to Org: ${currentMember.organization_id}`);

  // Create Auth User
  const { data, error: userError } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    user_metadata: {
      first_name,
      last_name,
      organization_id: currentMember.organization_id
    },
    email_confirm: true
  });

  // Remvoed inviteUserByEmail as we want immediate password access without links.
  // const { error: emailError } = await supabaseAdmin.auth.admin.inviteUserByEmail(email);

  if (!data?.user || userError) {
    console.error(`Error creating user: ${userError?.message}`);
    return createErrorResponse(500, "Failed to create user");
  }

  // Note: The 'handle_new_user' trigger has likely already created the 'employees' record
  // and 'org_members' record by now (synchronous trigger).

  // Post-process: Update status/role if needed
  try {
    // 1. Update Employee Status
    if (disabled) {
      await updateEmployee(data.user.id, { status: 'disabled' });
    }

    // 2. Update Role (if admin requested)
    // Trigger defaults to 'member'. Upgrade if needed.
    if (administrator) {
      await updateMemberRole(data.user.id, currentMember.organization_id, true);
    }

    // Return the new Employee record
    const employee = await getEmployee(data.user.id);

    // Shape response to match what frontend Setup might expect (legacy 'sales' shape compatibility?)
    // Or just return the employee.
    return new Response(
      JSON.stringify({ data: employee }),
      { headers: { "Content-Type": "application/json", ...corsHeaders } }
    );

  } catch (e) {
    console.error("Error post-processing user:", e);
    return createErrorResponse(500, "User created but failed to configure profile");
  }
}

async function patchUser(req: Request, currentMember: any) {
  const {
    sales_id, // Deprecated, but frontend passes it. It's likely the Employee ID or User ID?
    // Frontend currently passes 'id' of the record it has. If it was reading 'sales', it passed sales.id.
    // If we haven't updated frontend, this might be tricky.
    // BUT, we can assume 'sales_id' meant 'id' of the resource.
    // If the frontend is hitting this endpoint, it's sending the ID of the record in the URL or body.
    // Let's rely on 'email' to find the user? No, email can change.
    // Let's use the ID passed. If we migrated, the ID might be different if we switched tables.
    // CRITICAL: We need to know if 'sales_id' passed is user_id or legacy sales_id.
    // Update: frontend/SalesCreate passes body.
    // Let's try to lookup Employee by ID passed as sales_id.
    user_id_param, // Let's look for this (custom) or assume sales_id IS the ID.
    email,
    first_name,
    last_name,
    avatar,
    administrator,
    disabled,
  } = await req.json();

  // Find target employee
  // We assume sales_id maps to employee.user_id? No, employees.id.
  // We need to resolve Employee -> User ID.
  let targetUserVal = null;

  // Try finding employee by ID
  const { data: employee } = await supabaseAdmin
    .from("employees")
    .select("*")
    .eq("id", sales_id) // Try matching Employee ID
    .single();

  if (!employee) {
    // Fallback: This might be a User ID?
    // Or legacy Sales ID?
    // For now, return 404.
    return createErrorResponse(404, "Employee not found");
  }

  const targetUserId = employee.user_id;

  // Auth Check
  // Users can update themselves, Admins can update anyone in Org.
  const isSelf = currentMember.user_id === targetUserId;
  const isAdmin = currentMember.role === 'owner' || currentMember.role === 'admin';
  const isSameOrg = currentMember.organization_id === employee.organization_id;

  if (!isSameOrg) return createErrorResponse(401, "Not Authorized: Diff Org");
  if (!isSelf && !isAdmin) return createErrorResponse(401, "Not Authorized");

  // Update Auth User (Email/Metadata)
  const { user, error: userError } = await supabaseAdmin.auth.admin.updateUserById(targetUserId, {
    email,
    ban_duration: disabled ? "87600h" : "none",
    user_metadata: { first_name, last_name },
  });

  if (userError) {
    console.error("Error updating auth user:", userError);
    return createErrorResponse(500, "Failed to update auth user");
  }

  // Update Employee Profile
  await updateEmployee(targetUserId, {
    first_name,
    last_name,
    avatar,
    status: disabled ? 'disabled' : 'active'
  });

  // Update Role (Admins only)
  if (isAdmin && administrator !== undefined) {
    await updateMemberRole(targetUserId, currentMember.organization_id, administrator);
  }

  const updatedEmployee = await getEmployee(targetUserId);

  return new Response(
    JSON.stringify({ data: updatedEmployee }),
    { headers: { "Content-Type": "application/json", ...corsHeaders } }
  );
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization")!;
  const localClient = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await localClient.auth.getUser();
  if (!user) {
    return createErrorResponse(401, "Unauthorized");
  }

  // Fetch Current Member Info (Org + Role)
  const { data: member } = await supabaseAdmin
    .from("org_members")
    .select("*")
    .eq("user_id", user.id)
    .single();

  if (!member) {
    return createErrorResponse(401, "Unauthorized: No Org Membership");
  }

  if (req.method === "POST") {
    return inviteUser(req, member);
  }

  if (req.method === "PATCH") {
    return patchUser(req, member);
  }

  return createErrorResponse(405, "Method Not Allowed");
});
