-- Run this in your Supabase SQL Editor to allow 'Draft' status
ALTER TABLE public.agreements DROP CONSTRAINT IF EXISTS agreements_status_check;
ALTER TABLE public.agreements ADD CONSTRAINT agreements_status_check CHECK (status IN ('active', 'expired', 'Draft', 'Pending'));
