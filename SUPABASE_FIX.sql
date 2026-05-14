-- =====================================================================
-- AS-SUNNAH FOUNDATION TRACKER: SECURITY HARDENING (RLS) - UPDATED
-- Version: 1.3.1
-- Purpose: Fixing profile persistence and role synchronization (Idempotent)
-- =====================================================================

-- 1. PROFILE POLICIES
-- Drop existing to avoid "already exists" errors
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by owner or admin" ON public.profiles;

-- Allow users to insert their own profile during onboarding
CREATE POLICY "Users can insert their own profile" ON public.profiles
FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to update their own profile (phone, dept, etc.)
CREATE POLICY "Users can update their own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id);

-- Allow owner or admins to view profiles
CREATE POLICY "Profiles are viewable by owner or admin" ON public.profiles
FOR SELECT USING (
  auth.uid() = id OR 
  (SELECT (role = 'admin' OR role = 'manager') FROM public.profiles WHERE id = auth.uid())
);

-- 2. DAILY LOGS POLICIES
DROP POLICY IF EXISTS "Logs are manageable by owner" ON public.daily_logs;
DROP POLICY IF EXISTS "Admins can oversee all logs" ON public.daily_logs;

-- Allow users full control over their own logs
CREATE POLICY "Logs are manageable by owner" ON public.daily_logs
FOR ALL USING (auth.uid() = user_id);

-- Allow admins to view all logs for institutional oversight
CREATE POLICY "Admins can oversee all logs" ON public.daily_logs
FOR SELECT USING (
  (SELECT (role = 'admin' OR role = 'manager') FROM public.profiles WHERE id = auth.uid())
);

-- 3. ENSURE RLS IS ENABLED
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;
