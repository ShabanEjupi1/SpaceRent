-- SpaceRent Kosovo Database Migration v2
-- Run this in the Supabase SQL Editor (https://supabase.com/dashboard/project/rrjndmbihxblkwzwmhoi/sql)

-- 1. Create helper RPC function for the Database Explorer (runs arbitrary queries on behalf of admin)
CREATE OR REPLACE FUNCTION exec_sql(query_text text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result jsonb;
BEGIN
    IF query_text ILIKE 'select%' OR query_text ILIKE 'show%' OR query_text ILIKE 'explain%' OR query_text ILIKE 'with%' THEN
        EXECUTE 'SELECT json_agg(t) FROM (' || query_text || ') t' INTO result;
        RETURN json_build_object('data', COALESCE(result, '[]'::jsonb));
    ELSE
        EXECUTE query_text;
        RETURN json_build_object('message', 'Command executed successfully');
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('error', SQLERRM);
END;
$$;

-- 2. Add vehicle specifications columns
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS seats INT;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS doors INT;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS engine VARCHAR(255);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS description TEXT;

-- 3. Add payment_method to bookings table
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'Online' NOT NULL;

-- 4. Add passcode column to profiles table for dynamic admin passwords
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS passcode VARCHAR(255) DEFAULT '2026';

-- 5. Auto-create 'vehicle-images' storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-images', 'vehicle-images', true)
ON CONFLICT (id) DO NOTHING;

-- Configure storage policies for the 'vehicle-images' bucket
DROP POLICY IF EXISTS "Public Read Access" ON storage.objects;
CREATE POLICY "Public Read Access" ON storage.objects FOR SELECT USING (bucket_id = 'vehicle-images');

DROP POLICY IF EXISTS "Public Write Access" ON storage.objects;
CREATE POLICY "Public Write Access" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'vehicle-images');

DROP POLICY IF EXISTS "Public Update Access" ON storage.objects;
CREATE POLICY "Public Update Access" ON storage.objects FOR UPDATE USING (bucket_id = 'vehicle-images') WITH CHECK (bucket_id = 'vehicle-images');

DROP POLICY IF EXISTS "Public Delete Access" ON storage.objects;
CREATE POLICY "Public Delete Access" ON storage.objects FOR DELETE USING (bucket_id = 'vehicle-images');

-- 6. Add auto_confirm settings to partners and profiles
ALTER TABLE partners ADD COLUMN IF NOT EXISTS auto_confirm BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auto_confirm BOOLEAN DEFAULT FALSE;

-- 7. Create profile change requests table for partners
CREATE TABLE IF NOT EXISTS profile_change_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_id UUID REFERENCES partners(id) ON DELETE CASCADE,
    company_name VARCHAR(255),
    contact_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(255),
    status VARCHAR(50) DEFAULT 'Pending' NOT NULL, -- 'Pending', 'Approved', 'Rejected'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Enable RLS and add public access policies for profile_change_requests
ALTER TABLE profile_change_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public access to profile_change_requests" ON profile_change_requests;
CREATE POLICY "Allow public access to profile_change_requests" ON profile_change_requests FOR ALL USING (true);
