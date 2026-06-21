-- Run this in your Supabase SQL Editor to support unregistered tenants
ALTER TABLE public.tenants ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS tenant_name VARCHAR;
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS tenant_mobile VARCHAR;
