TRUNCATE TABLE "public"."tasks", "public"."dealNotes", "public"."contactNotes", "public"."deals", "public"."contacts", "public"."companies" CASCADE;

-- Insert 6 Companies
INSERT INTO "public"."companies" (name, sector, size, website, sales_id, created_at)
VALUES 
 ('Acme Corporation', 'Technology', 100, 'www.acme.com', 1, now()),
 ('Globex Inc', 'Logistics', 500, 'www.globex.com', 1, now()),
 ('Soylent Corp', 'Food', 200, 'www.soylent.com', 1, now()),
 ('Initech', 'Software', 50, 'www.initech.com', 1, now()),
 ('Umbrella Corp', 'Pharma', 1000, 'www.umbrella.com', 1, now()),
 ('Stark Industries', 'Defense', 5000, 'www.stark.com', 1, now());

-- Insert 10 Contacts
INSERT INTO "public"."contacts" (first_name, last_name, email_jsonb, company_id, sales_id, status)
SELECT 
  'Contact', 'Person ' || seq, 
  jsonb_build_array(jsonb_build_object('email', 'contact' || seq || '@test.com', 'type', 'Work')),
  (SELECT id FROM "public"."companies" ORDER BY random() LIMIT 1),
  1,
  'New'
FROM generate_series(1, 10) seq;

-- Insert 10 Deals
INSERT INTO "public"."deals" (name, amount, stage, company_id, sales_id)
SELECT 
  'Deal ' || seq, (floor(random() * 100000) + 1000)::int, 
  (ARRAY['New', 'Qualified', 'Negotiation', 'Won'])[floor(random() * 4) + 1],
  (SELECT id FROM "public"."companies" ORDER BY random() LIMIT 1),
  1
FROM generate_series(1, 10) seq;

-- Insert 20 Tasks (Activities)
INSERT INTO "public"."tasks" (type, text, due_date, contact_id)
SELECT 
  (ARRAY['Email', 'Call', 'Meeting'])[floor(random() * 3) + 1],
  'Follow up activity ' || seq,
  now() + (seq || ' days')::interval,
  (SELECT id FROM "public"."contacts" ORDER BY random() LIMIT 1)
FROM generate_series(1, 20) seq;
