-- cron_renewal_leads.sql

-- 1. Create the function to find expiring agreements and insert them as renewal leads
CREATE OR REPLACE FUNCTION public.generate_renewal_leads()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.renewal_leads (agreement_id, expiry_date, days_until_expiry, status)
  SELECT 
    a.id, 
    a.expiry_date, 
    (a.expiry_date - CURRENT_DATE)::int AS days_until_expiry,
    'New'
  FROM public.agreements a
  LEFT JOIN public.renewal_leads rl ON a.id = rl.agreement_id
  WHERE a.status = 'active'
    AND a.expiry_date <= CURRENT_DATE + INTERVAL '45 days'
    AND rl.id IS NULL; -- Ensures we don't insert duplicates for the same agreement
END;
$$;

-- 2. Optional: If you enable the pg_cron extension in your Supabase dashboard, 
--    you can uncomment and run the following line to schedule it daily at midnight (UTC).
-- SELECT cron.schedule('generate_renewals_daily', '0 0 * * *', 'SELECT public.generate_renewal_leads()');
