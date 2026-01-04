SELECT 'companies' AS table_name, count(*) AS record_count FROM public.companies
UNION ALL
SELECT 'contacts' AS table_name, count(*) AS record_count FROM public.contacts
UNION ALL
SELECT 'deals' AS table_name, count(*) AS record_count FROM public.deals
UNION ALL
SELECT 'tasks' AS table_name, count(*) AS record_count FROM public.tasks;
