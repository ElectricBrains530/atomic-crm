
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

// Load env vars
dotenv.config({ path: ".env.local" });

const supabaseUrl = process.env.VITE_SUPABASE_URL || "http://127.0.0.1:54321";
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseAnonKey) {
    console.error("Missing VITE_SUPABASE_ANON_KEY");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function verify() {
    console.log("1. Signing in as fox@foxden.com...");
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: "fox@foxden.com",
        password: "password",
    });

    if (authError || !authData.session) {
        console.error("Sign in failed:", authError);
        return;
    }

    const token = authData.session.access_token;
    console.log("   Sign in successful. User ID:", authData.user.id);

    // We need to find the organization ID for "Fox Den"
    console.log("2. Fetching Organization ID...");
    const { data: orgs, error: orgError } = await supabase
        .from("organizations")
        .select("id, name")
        .ilike("name", "Fox Den");

    if (orgError || !orgs || orgs.length === 0) {
        console.error("   Could not find 'Fox Den' organization:", orgError);
        return;
    }

    const orgId = orgs[0].id;
    console.log(`   Found Organization: ${orgs[0].name} (ID: ${orgId})`);

    console.log("3. Creating Company 'Boggis Farms' via REST API with Header...");

    // We use fetch directly to inspect headers response and control the request precisely.
    // This mimics what the monkey-patched fetch does in the frontend.
    const response = await fetch(`${supabaseUrl}/rest/v1/companies`, {
        method: "POST",
        headers: {
            "apikey": supabaseAnonKey,
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json",
            "Prefer": "return=representation",
            "x-organization-id": orgId.toString() // THE FIX: Injecting the header
        },
        body: JSON.stringify({
            name: "Boggis Farms (Verified via Script)",
            organization_id: null // Explicitly null to prove the trigger fills it using the header
        })
    });

    if (!response.ok) {
        const text = await response.text();
        console.error(`   Request Failed: ${response.status} ${response.statusText}`);
        console.error(`   Response Body: ${text}`);
        return;
    }

    const result = await response.json();
    console.log("   Success! Created Company:", result);
    console.log("   Verified that 'organization_id' was populated:", result[0].organization_id);

    if (result[0].organization_id == orgId) {
        console.log("   PASS: Organization ID matches active context.");
    } else {
        console.error("   FAIL: Organization ID mismatch!");
    }
}

verify();
