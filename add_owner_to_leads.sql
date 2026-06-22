ALTER TABLE public.leads 
ADD COLUMN owner_id UUID REFERENCES public.users(id);
