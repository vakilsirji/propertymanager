-- Run this in your Supabase SQL Editor to support detailed draft agreements
ALTER TABLE public.agreements ADD COLUMN IF NOT EXISTS details JSONB;
