-- Database Schema for SpaceRent Kosovo

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Locations Table (Kosovo Hubs)
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en VARCHAR(255) NOT NULL,
    name_sq VARCHAR(255) NOT NULL,
    name_sr VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE, -- e.g., 'PRN' for Pristina Airport
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed Locations
INSERT INTO locations (name_en, name_sq, name_sr, code) VALUES
('Pristina International Airport (PRN)', 'Aeroporti Ndërkombëtar i Prishtinës (PRN)', 'Međunarodni Aerodrom Priština (PRN)', 'PRN'),
('Pristina Center', 'Prishtinë Qendër', 'Priština Centar', 'PR-CEN'),
('Prizren Hub', 'Prizren Qendër', 'Prizren Centar', 'PZ-HUB'),
('Peja Hub', 'Pejë Qendër', 'Peć Centar', 'PE-HUB')
ON CONFLICT (code) DO NOTHING;

-- 2. Partners Table
CREATE TABLE IF NOT EXISTS partners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'Active' NOT NULL, -- 'Active', 'Suspended'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Vehicles Table
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    transmission VARCHAR(50) NOT NULL, -- 'Automatic', 'Manual'
    fuel_type VARCHAR(50) NOT NULL, -- 'Diesel', 'Petrol', 'Electric', 'Hybrid'
    has_ac BOOLEAN DEFAULT TRUE NOT NULL,
    price_per_day NUMERIC(10, 2) NOT NULL,
    image_url VARCHAR(500),
    location_id UUID REFERENCES locations(id) ON DELETE SET NULL,
    partner_id UUID REFERENCES partners(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed Premium Vehicles
INSERT INTO vehicles (brand, model, year, transmission, fuel_type, has_ac, price_per_day, image_url, location_id)
SELECT 'Audi', 'A6 S-Line', 2023, 'Automatic', 'Diesel', true, 65.00, 'https://images.unsplash.com/photo-1606016159991-dfe4f2746ad5?auto=format&fit=crop&q=80&w=600', id FROM locations WHERE code = 'PRN'
LIMIT 1;

INSERT INTO vehicles (brand, model, year, transmission, fuel_type, has_ac, price_per_day, image_url, location_id)
SELECT 'Volkswagen', 'Golf 8 R-Line', 2022, 'Automatic', 'Petrol', true, 45.00, 'https://images.unsplash.com/photo-1617650728468-8581e439c864?auto=format&fit=crop&q=80&w=600', id FROM locations WHERE code = 'PRN'
LIMIT 1;

INSERT INTO vehicles (brand, model, year, transmission, fuel_type, has_ac, price_per_day, image_url, location_id)
SELECT 'BMW', '5 Series', 2023, 'Automatic', 'Diesel', true, 75.00, 'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=600', id FROM locations WHERE code = 'PR-CEN'
LIMIT 1;

INSERT INTO vehicles (brand, model, year, transmission, fuel_type, has_ac, price_per_day, image_url, location_id)
SELECT 'Mercedes-Benz', 'C-Class', 2022, 'Automatic', 'Diesel', true, 70.00, 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&q=80&w=600', id FROM locations WHERE code = 'PZ-HUB'
LIMIT 1;

-- 4. Bookings Table
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    total_price NUMERIC(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending' NOT NULL, -- 'Pending', 'Confirmed', 'Cancelled'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_dates CHECK (end_date > start_date)
);

-- 5. Partner Applications Table
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

-- Enable RLS
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_applications ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Allow public read access to locations" ON locations;
CREATE POLICY "Allow public read access to locations" ON locations FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read access to vehicles" ON vehicles;
CREATE POLICY "Allow public read access to vehicles" ON vehicles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow users to view their own bookings" ON bookings;
CREATE POLICY "Allow users to view their own bookings" ON bookings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow users to insert bookings" ON bookings;
CREATE POLICY "Allow users to insert bookings" ON bookings FOR INSERT WITH CHECK (true);

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

