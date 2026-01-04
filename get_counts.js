import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
    'http://127.0.0.1:54321',
    'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
    { auth: { autoRefreshToken: false, persistSession: false } }
)

async function getCounts() {
    const tables = ['companies', 'contacts', 'deals', 'tasks'];
    const results = [];

    for (const table of tables) {
        const { count, error } = await supabase
            .from(table)
            .select('*', { count: 'exact', head: true });

        if (error) {
            console.error(`Error counting ${table}:`, error.message);
            results.push({ Table: table, Count: 'Error' });
        } else {
            results.push({ Table: table, Count: count });
        }
    }

    console.table(results);
}

getCounts();
