-- Run this in your Supabase SQL Editor to allow Quick Add of Properties and Tenants

-- 1. Relax Properties table constraints
ALTER TABLE public.properties ALTER COLUMN owner_id DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN property_name DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN city DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN rent_amount DROP NOT NULL;
ALTER TABLE public.properties ALTER COLUMN deposit DROP NOT NULL;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS owner_name VARCHAR;
ALTER TABLE public.properties DROP CONSTRAINT IF EXISTS properties_status_check;
ALTER TABLE public.properties ADD CONSTRAINT properties_status_check CHECK (status IN ('active', 'vacant', 'available'));

-- 2. Relax Users table constraints (allows adding offline clients without Auth accounts)
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;
ALTER TABLE public.users ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.users ALTER COLUMN email DROP NOT NULL;
