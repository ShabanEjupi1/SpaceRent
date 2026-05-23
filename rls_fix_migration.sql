-- ============================================================
-- SpaceRent Kosovo — RLS Fix + Schema Enhancement Migration
-- Run this in Supabase SQL Editor to fix all CRUD operations
-- ============================================================

-- ============================================================
-- 1. FIX: Missing RLS policies for VEHICLES (UPDATE + DELETE)
-- ============================================================
DROP POLICY IF EXISTS "Allow update on vehicles" ON vehicles;
CREATE POLICY "Allow update on vehicles" ON vehicles
  FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete on vehicles" ON vehicles;
CREATE POLICY "Allow delete on vehicles" ON vehicles
  FOR DELETE USING (true);

-- ============================================================
-- 2. FIX: Missing RLS policies for BOOKINGS (UPDATE + DELETE)
-- ============================================================
DROP POLICY IF EXISTS "Allow update on bookings" ON bookings;
CREATE POLICY "Allow update on bookings" ON bookings
  FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete on bookings" ON bookings;
CREATE POLICY "Allow delete on bookings" ON bookings
  FOR DELETE USING (true);

-- ============================================================
-- 3. FIX: Missing RLS policies for PARTNERS (UPDATE + DELETE)
-- ============================================================
DROP POLICY IF EXISTS "Allow update on partners" ON partners;
CREATE POLICY "Allow update on partners" ON partners
  FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete on partners" ON partners;
CREATE POLICY "Allow delete on partners" ON partners
  FOR DELETE USING (true);

-- ============================================================
-- 4. FIX: Missing RLS policies for LOCATIONS (INSERT + UPDATE + DELETE)
-- ============================================================
DROP POLICY IF EXISTS "Allow insert on locations" ON locations;
CREATE POLICY "Allow insert on locations" ON locations
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update on locations" ON locations;
CREATE POLICY "Allow update on locations" ON locations
  FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow delete on locations" ON locations;
CREATE POLICY "Allow delete on locations" ON locations
  FOR DELETE USING (true);

-- ============================================================
-- 5. ENHANCEMENT: Add 'language' column to bookings
-- Tracks the locale the customer used when making the booking
-- ============================================================
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS language VARCHAR(5) DEFAULT 'en';

-- ============================================================
-- 6. ENHANCEMENT: Add 'image_urls' column to vehicles
-- Supports multiple vehicle images as a JSON array
-- ============================================================
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS image_urls JSONB DEFAULT '[]'::jsonb;

-- Migrate existing image_url values into the image_urls array
UPDATE vehicles
SET image_urls = jsonb_build_array(image_url)
WHERE image_url IS NOT NULL
  AND image_url != ''
  AND (image_urls IS NULL OR image_urls = '[]'::jsonb);

-- ============================================================
-- 7. Create Supabase Storage bucket for vehicle images
-- NOTE: This must be done via Supabase Dashboard > Storage
-- Create a bucket named "vehicle-images" with public access
-- ============================================================
-- Run in Supabase Dashboard:
-- 1. Go to Storage > New Bucket
-- 2. Name: vehicle-images
-- 3. Public: Yes
-- 4. File size limit: 5MB
-- 5. Allowed MIME types: image/jpeg, image/png, image/webp
