# WoTi Attendance App - Database Setup

## Required Database Tables

This app requires the following Supabase database setup:

### 1. Execute the SQL Schema

Run the `database_schema.sql` file in your Supabase SQL editor to create:
- `attendance` table with all necessary fields
- Proper indexes for performance
- Row Level Security (RLS) policies
- Storage bucket for attendance photos
- Auto-updating timestamp triggers

### 2. Verify Required Tables

Make sure these tables exist in your database:
- `regions` (id, name)
- `councils` (id, name, region_id)
- `facilities` (id, name, council_id, latitude, longitude)
- `user_profiles` (id, name, role, facility_id)
- `attendance` (created by the schema file)

### 3. Storage Configuration

The app uses Supabase Storage for attendance photos:
- Bucket name: `attendance_photos`
- Public access enabled
- Proper RLS policies for authenticated uploads

### 4. Facility Coordinates

For the geolocation validation to work properly, make sure your `facilities` table has:
- `latitude` column (DECIMAL)
- `longitude` column (DECIMAL)

You can add these columns if they don't exist:
```sql
ALTER TABLE facilities ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE facilities ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);
```

Then update your facilities with their actual coordinates.

## App Features

The attendance screen includes:
- ✅ Real-time clock and current date display
- ✅ User's current status (checked in/out)
- ✅ Current location coordinates (latitude/longitude)
- ✅ Location-based validation (100m facility radius)
- ✅ Check-in and check-out buttons with GPS capture
- ✅ Facility information and distance calculation
- ✅ Photo capture functionality for check-in/out
- ✅ Hours calculation when checking out
- ✅ Proper error handling for permissions and network issues
- ✅ Supabase integration with RLS security
- ✅ Responsive dark theme design

## Required Permissions

The app requires these device permissions:
- **Location Services**: For GPS coordinates and facility validation
- **Camera**: For capturing attendance photos
- **Storage**: For saving photos before upload

Permissions are handled gracefully with proper error messages if denied.