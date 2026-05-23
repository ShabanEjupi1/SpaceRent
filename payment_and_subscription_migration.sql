-- Migration to support user payments and partner subscriptions

-- 1. Alter bookings table to add payment status and payment reference
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'Unpaid' NOT NULL;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS paypal_order_id VARCHAR(255);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP WITH TIME ZONE;

-- 2. Alter partners table to add subscription details
ALTER TABLE partners ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'Inactive' NOT NULL;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE partners ADD COLUMN IF NOT EXISTS paypal_subscription_id VARCHAR(255);

-- 3. Create payments log table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    partner_id UUID REFERENCES partners(id) ON DELETE SET NULL,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'EUR' NOT NULL,
    payment_type VARCHAR(50) NOT NULL, -- 'BookingPayment', 'PartnerSubscription'
    paypal_order_id VARCHAR(255) UNIQUE,
    paypal_subscription_id VARCHAR(255),
    status VARCHAR(50) NOT NULL, -- 'Pending', 'Completed', 'Failed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS on payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Payments policies
DROP POLICY IF EXISTS "Allow public read of payments" ON payments;
CREATE POLICY "Allow public read of payments" ON payments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert of payments" ON payments;
CREATE POLICY "Allow public insert of payments" ON payments FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update of payments" ON payments;
CREATE POLICY "Allow update of payments" ON payments FOR UPDATE USING (true) WITH CHECK (true);
