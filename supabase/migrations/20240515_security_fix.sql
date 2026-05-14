-- =====================================================================
-- AS-SUNNAH FOUNDATION TRACKER: SECURITY HARDENING (RLS)
-- Version: 1.3
-- Purpose: Fixing profile persistence and role synchronization
-- =====================================================================

-- 1. ADD MISSING PROFILE POLICIES
-- Allow users to insert their own profile during onboarding
CREATE POLICY "Users can insert their own profile" ON public.profiles
FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to update their own profile (phone, dept, etc.)
CREATE POLICY "Users can update their own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id);

-- 2. ENSURE ADMINS CAN VIEW ALL PROFILES (Already exists, but hardening)
DROP POLICY IF EXISTS "Profiles are viewable by owner or admin" ON public.profiles;
CREATE POLICY "Profiles are viewable by owner or admin" ON public.profiles
FOR SELECT USING (
  auth.uid() = id OR 
  (SELECT (role = 'admin' OR role = 'manager') FROM public.profiles WHERE id = auth.uid())
);

-- 3. FIX DAILY LOGS RLS (Add INSERT/UPDATE if missing)
DROP POLICY IF EXISTS "Logs are manageable by owner" ON public.daily_logs;
CREATE POLICY "Logs are manageable by owner" ON public.daily_logs
FOR ALL USING (auth.uid() = user_id);

-- 4. SERVICE ROLE BYPASS (Internal cleanup)
-- Ensure system triggers can always operate
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;
