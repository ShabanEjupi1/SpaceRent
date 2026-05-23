-- SpaceRent Kosovo Database Migration

-- 1. Add contact detail fields to bookings table
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS full_name VARCHAR(255);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS phone_number VARCHAR(50);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS email_address VARCHAR(255);

-- 2. Create profiles table for user management
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'Customer' NOT NULL, -- 'Admin', 'Partner', 'Customer'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Seed default Admin profile
INSERT INTO profiles (id, email, role) VALUES
('eb3d0851-c518-4034-b806-c88411160e24', 'shaban.ejj@gmail.com', 'Admin')
ON CONFLICT (email) DO UPDATE SET role = 'Admin';

-- 4. Enable Row Level Security (RLS) on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 5. Establish policies for profiles
DROP POLICY IF EXISTS "Allow public read of profiles" ON profiles;
CREATE POLICY "Allow public read of profiles" ON profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert of profiles" ON profiles;
CREATE POLICY "Allow public insert of profiles" ON profiles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all modifications on profiles" ON profiles;
CREATE POLICY "Allow all modifications on profiles" ON profiles FOR ALL USING (true);
