-- alter_biometric.sql
-- Add vendor_id to biometric_visits to securely link to the users table

ALTER TABLE public.biometric_visits
ADD COLUMN vendor_id UUID REFERENCES public.users(id);

-- Optional: If you want to enforce RLS for vendors, uncomment and adjust the policy below
-- CREATE POLICY "Vendors can view their own visits" ON public.biometric_visits
-- FOR SELECT USING (auth.role() = 'authenticated' AND vendor_id = auth.uid());

-- CREATE POLICY "Vendors can update their own visits" ON public.biometric_visits
-- FOR UPDATE USING (auth.role() = 'authenticated' AND vendor_id = auth.uid());
