-- clear_test_data.sql
-- Run this in the Supabase SQL Editor to wipe all test records and reset IDs to 1.
-- This WILL NOT delete your Admin user account.

TRUNCATE TABLE 
  public.rent_payments, 
  public.agreements, 
  public.tenants, 
  public.properties 
RESTART IDENTITY CASCADE;

-- Note: To delete the actual PDF files, go to Supabase Dashboard -> Storage 
-- and delete the files inside the 'agreements' and 'lead_documents' buckets manually.
