-- Run this in your Supabase SQL Editor to create the bucket for document uploads

INSERT INTO storage.buckets (id, name, public) 
VALUES ('lead_documents', 'lead_documents', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Access" 
ON storage.objects FOR ALL 
USING (bucket_id = 'lead_documents');
