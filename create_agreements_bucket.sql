-- Run this in your Supabase SQL Editor to create the bucket for PDF Agreements

-- 1. Create a public storage bucket named 'agreements'
INSERT INTO storage.buckets (id, name, public) VALUES ('agreements', 'agreements', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Allow public read access to the bucket
CREATE POLICY "Public Read Access" ON storage.objects FOR SELECT USING (bucket_id = 'agreements');

-- 3. Allow authenticated users to upload and update PDFs in the bucket
CREATE POLICY "Authenticated Upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'agreements' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated Update" ON storage.objects FOR UPDATE USING (bucket_id = 'agreements' AND auth.role() = 'authenticated');
