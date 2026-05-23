-- Multi-Tenant Partner Expansion Schema

-- 1. Partners Table
CREATE TABLE IF NOT EXISTS partners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'Active' NOT NULL, -- 'Active', 'Suspended'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Partner Applications Table
CREATE TABLE IF NOT EXISTS partner_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending' NOT NULL, -- 'Pending', 'Approved', 'Rejected'
    invite_token VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Modify Vehicles Table to support Partner ownership
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS partner_id UUID REFERENCES partners(id) ON DELETE SET NULL;

-- Enable RLS
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert of partner applications" ON partner_applications;
CREATE POLICY "Allow public insert of partner applications" ON partner_applications FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow admin read of partner applications" ON partner_applications;
CREATE POLICY "Allow admin read of partner applications" ON partner_applications FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow admin update of partner applications" ON partner_applications;
CREATE POLICY "Allow admin update of partner applications" ON partner_applications FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow public read of partners" ON partners;
CREATE POLICY "Allow public read of partners" ON partners FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert of partners" ON partners;
CREATE POLICY "Allow public insert of partners" ON partners FOR INSERT WITH CHECK (true);

