-- Complete Supabase Schema for LifeSync App
-- This file contains all tables, indexes, RLS policies, storage buckets, and triggers

-- User Profiles table to store user roles and family hierarchy
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    avatar TEXT,
    user_type TEXT NOT NULL DEFAULT 'admin', -- 'admin' (registered) or 'client' (created by admin)
    role TEXT NOT NULL DEFAULT 'owner', -- 'owner' or 'member' within family
    parent_user_id UUID REFERENCES auth.users (id), -- The admin who created this client user
    family_id UUID, -- Links family members together
    relation TEXT, -- Relationship to the admin (e.g., 'spouse', 'child')
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP
    WITH
        TIME ZONE,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- Create tables
CREATE TABLE IF NOT EXISTS expenses (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    description TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    category TEXT NOT NULL,
    date TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        payment_method TEXT,
        notes TEXT,
        family_member_id TEXT,
        contact_name TEXT,
        phone_number TEXT,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS incomes (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    description TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    source TEXT NOT NULL,
    date TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        is_recurring BOOLEAN DEFAULT FALSE,
        recurring_frequency TEXT,
        notes TEXT,
        family_member_id TEXT,
        contact_name TEXT,
        phone_number TEXT,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS budgets (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    category TEXT NOT NULL,
    allocated_amount DECIMAL(10, 2) NOT NULL,
    spent_amount DECIMAL(10, 2) DEFAULT 0,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    alert_threshold DECIMAL(5, 2) DEFAULT 80,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS family_members (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    name TEXT NOT NULL,
    relationship TEXT,
    birth_date DATE,
    phone_number TEXT,
    email TEXT,
    notes TEXT,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS family_numbers (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    category TEXT NOT NULL,
    is_emergency BOOLEAN DEFAULT FALSE,
    is_primary BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    priority TEXT DEFAULT 'Medium',
    status TEXT DEFAULT 'Pending',
    due_date TIMESTAMP
    WITH
        TIME ZONE,
        is_completed BOOLEAN DEFAULT FALSE,
        completed_at TIMESTAMP
    WITH
        TIME ZONE,
        assigned_to TEXT,
        notes TEXT,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS savings_goals (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    title TEXT NOT NULL,
    description TEXT,
    target_amount DECIMAL(10, 2) NOT NULL,
    current_amount DECIMAL(10, 2) DEFAULT 0,
    target_date DATE,
    category TEXT,
    priority TEXT DEFAULT 'Medium',
    is_completed BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reminders (
    id UUID DEFAULT gen_random_uuid () PRIMARY KEY,
    user_id UUID REFERENCES auth.users (id),
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    amount DECIMAL(10, 2),
    due_date TIMESTAMP
    WITH
        TIME ZONE NOT NULL,
        is_paid BOOLEAN DEFAULT FALSE,
        repeat_interval TEXT,
        notes TEXT,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  member_name TEXT NOT NULL,
  record_type TEXT NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  diagnosis TEXT,
  treatment TEXT,
  next_visit DATE,
  doctor_name TEXT,
  doctor_phone TEXT,
  hospital_name TEXT,
  medication TEXT,
  dosage TEXT,
  frequency TEXT,
  notes TEXT,
  -- Media attachments for health records (like WhatsApp images)
  attachments TEXT[], -- Array of attachment URLs/filenames
  image_urls TEXT[], -- Separate array for image URLs specifically
  file_paths TEXT[], -- Array for file paths in storage
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

ALTER TABLE incomes ENABLE ROW LEVEL SECURITY;

ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

ALTER TABLE family_numbers ENABLE ROW LEVEL SECURITY;

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;

ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_type ON user_profiles (user_type);

CREATE INDEX IF NOT EXISTS idx_user_profiles_parent_user_id ON user_profiles (parent_user_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_family_id ON user_profiles (family_id);

CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses (user_id);

CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses (category);

CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses (date);

CREATE INDEX IF NOT EXISTS idx_expenses_family_member ON expenses (family_member_id);

CREATE INDEX IF NOT EXISTS idx_incomes_user_id ON incomes (user_id);

CREATE INDEX IF NOT EXISTS idx_incomes_source ON incomes (source);

CREATE INDEX IF NOT EXISTS idx_incomes_date ON incomes (date);

CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets (user_id);

CREATE INDEX IF NOT EXISTS idx_budgets_category_year_month ON budgets (
    user_id,
    category,
    year,
    month
);

CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family_members (user_id);

CREATE INDEX IF NOT EXISTS idx_family_numbers_user_id ON family_numbers (user_id);

CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks (user_id);

CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks (due_date);

CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks (priority);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks (status);

CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON savings_goals (user_id);

CREATE INDEX IF NOT EXISTS idx_savings_goals_is_completed ON savings_goals (is_completed);

CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON reminders (user_id);

CREATE INDEX IF NOT EXISTS idx_reminders_due_date ON reminders (due_date);

CREATE INDEX IF NOT EXISTS idx_reminders_is_paid ON reminders (is_paid);

CREATE INDEX IF NOT EXISTS idx_health_records_user_id ON health_records (user_id);

CREATE INDEX IF NOT EXISTS idx_health_records_member_name ON health_records (member_name);

CREATE INDEX IF NOT EXISTS idx_health_records_record_type ON health_records (record_type);

CREATE INDEX IF NOT EXISTS idx_health_records_date ON health_records (date);

-- RLS Policies
-- Expenses
CREATE POLICY "Users can view their own expenses" ON expenses FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own expenses" ON expenses FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own expenses" ON expenses FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own expenses" ON expenses FOR DELETE USING (auth.uid () = user_id);

-- Incomes
CREATE POLICY "Users can view their own incomes" ON incomes FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own incomes" ON incomes FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own incomes" ON incomes FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own incomes" ON incomes FOR DELETE USING (auth.uid () = user_id);

-- Budgets
CREATE POLICY "Users can view their own budgets" ON budgets FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own budgets" ON budgets FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own budgets" ON budgets FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own budgets" ON budgets FOR DELETE USING (auth.uid () = user_id);

-- Family Members
CREATE POLICY "Users can view their own family members" ON family_members FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own family members" ON family_members FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own family members" ON family_members FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own family members" ON family_members FOR DELETE USING (auth.uid () = user_id);

-- Family Numbers
CREATE POLICY "Users can view their own family numbers" ON family_numbers FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own family numbers" ON family_numbers FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own family numbers" ON family_numbers FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own family numbers" ON family_numbers FOR DELETE USING (auth.uid () = user_id);

-- Tasks
CREATE POLICY "Users can view their own tasks" ON tasks FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own tasks" ON tasks FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own tasks" ON tasks FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own tasks" ON tasks FOR DELETE USING (auth.uid () = user_id);

-- Savings Goals
CREATE POLICY "Users can view their own savings goals" ON savings_goals FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own savings goals" ON savings_goals FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own savings goals" ON savings_goals FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own savings goals" ON savings_goals FOR DELETE USING (auth.uid () = user_id);

-- Reminders
CREATE POLICY "Users can view their own reminders" ON reminders FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own reminders" ON reminders FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own reminders" ON reminders FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own reminders" ON reminders FOR DELETE USING (auth.uid () = user_id);

-- Health Records
CREATE POLICY "Users can view their own health records" ON health_records FOR
SELECT USING (auth.uid () = user_id);

CREATE POLICY "Users can insert their own health records" ON health_records FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

CREATE POLICY "Users can update their own health records" ON health_records FOR
UPDATE USING (auth.uid () = user_id);

CREATE POLICY "Users can delete their own health records" ON health_records FOR DELETE USING (auth.uid () = user_id);

-- User Profiles
-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON user_profiles FOR
SELECT USING (auth.uid () = id);

-- Admins can view profiles of client users they created
CREATE POLICY "Admins can view their client profiles" ON user_profiles FOR
SELECT USING (auth.uid () = parent_user_id);

-- Users can insert their own profile (for registration)
CREATE POLICY "Users can insert their own profile" ON user_profiles FOR
INSERT
WITH
    CHECK (auth.uid () = id);

-- Admins can insert client profiles
CREATE POLICY "Admins can insert client profiles" ON user_profiles FOR
INSERT
WITH
    CHECK (
        auth.uid () = parent_user_id
        AND user_type = 'client'
    );

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON user_profiles FOR
UPDATE USING (auth.uid () = id);

-- Admins can update their client profiles
CREATE POLICY "Admins can update their client profiles" ON user_profiles FOR
UPDATE USING (auth.uid () = parent_user_id);

-- Admins can delete their client profiles
CREATE POLICY "Admins can delete their client profiles" ON user_profiles FOR DELETE USING (auth.uid () = parent_user_id);

-- Storage bucket for health record images
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'health-images') THEN
        INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
        VALUES ('health-images', 'health-images', false, true, 5242880, '{image/png,image/jpeg,image/gif,image/webp,image/jpg}');
    END IF;
END $$;

-- RLS Policies for storage (only create if they don't exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow individual access') THEN
        CREATE POLICY "Allow individual access" ON storage.objects
        FOR SELECT TO authenticated
        USING (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow individual uploads') THEN
        CREATE POLICY "Allow individual uploads" ON storage.objects
        FOR INSERT TO authenticated
        WITH CHECK (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow individual updates') THEN
        CREATE POLICY "Allow individual updates" ON storage.objects
        FOR UPDATE TO authenticated
        USING (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow individual deletes') THEN
        CREATE POLICY "Allow individual deletes" ON storage.objects
        FOR DELETE TO authenticated
        USING (bucket_id = 'health-images' AND (storage.foldername(name))[1] = auth.uid()::text);
    END IF;
END $$;

-- Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incomes_updated_at BEFORE UPDATE ON incomes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_family_members_updated_at BEFORE UPDATE ON family_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_family_numbers_updated_at BEFORE UPDATE ON family_numbers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_savings_goals_updated_at BEFORE UPDATE ON savings_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON reminders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_health_records_updated_at BEFORE UPDATE ON health_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create custom roles for different user types
DO $$
BEGIN
    -- Create owner role if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'owner') THEN
        CREATE ROLE owner;
    END IF;
    
    -- Create client role if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'client') THEN
        CREATE ROLE client;
    END IF;
END $$;

-- Grant appropriate permissions to roles
GRANT USAGE ON SCHEMA public TO owner, client;

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON ALL TABLES IN SCHEMA public TO owner,
client;

GRANT USAGE,
SELECT
    ON ALL SEQUENCES IN SCHEMA public TO owner,
    client;

-- Allow owner role to create other users
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'owner') THEN
        -- Grant the ability to create other users to the owner role
        GRANT ALL PRIVILEGES ON TABLE auth.users TO owner;
    END IF;
END $$;