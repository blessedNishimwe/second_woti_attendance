-- Attendance table schema for Supabase
-- This table should be created in your Supabase database

CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    facility_id UUID REFERENCES facilities(id) ON DELETE CASCADE,
    check_in_time TIMESTAMPTZ NOT NULL,
    check_out_time TIMESTAMPTZ,
    check_in_latitude DECIMAL(10, 8),
    check_in_longitude DECIMAL(11, 8),
    check_out_latitude DECIMAL(10, 8),
    check_out_longitude DECIMAL(11, 8),
    check_in_photo TEXT,
    check_out_photo TEXT,
    hours_worked DECIMAL(5, 2),
    status TEXT NOT NULL DEFAULT 'checked_in' CHECK (status IN ('checked_in', 'completed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_facility_id ON attendance(facility_id);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON attendance(check_in_time);

-- Enable Row Level Security (RLS)
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own attendance records
CREATE POLICY "Users can view own attendance" ON attendance FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own attendance records
CREATE POLICY "Users can insert own attendance" ON attendance FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own attendance records
CREATE POLICY "Users can update own attendance" ON attendance FOR UPDATE USING (auth.uid() = user_id);

-- Create storage bucket for attendance photos (if it doesn't exist)
-- This should be run in the Supabase SQL editor or through the dashboard
INSERT INTO storage.buckets (id, name, public) VALUES ('attendance_photos', 'attendance_photos', true) ON CONFLICT DO NOTHING;

-- Set up storage policies for attendance photos
CREATE POLICY "Anyone can view attendance photos" ON storage.objects FOR SELECT USING (bucket_id = 'attendance_photos');
CREATE POLICY "Users can upload attendance photos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'attendance_photos' AND auth.role() = 'authenticated');

-- Add facility coordinates if not present (optional, depends on existing schema)
-- ALTER TABLE facilities ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
-- ALTER TABLE facilities ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE
ON attendance FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();