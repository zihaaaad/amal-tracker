-- =====================================================================
-- AS-SUNNAH FOUNDATION TRACKER: RECURSION FIX & SECURITY HARDENING
-- Version: 1.5
-- Purpose: Resolving "infinite recursion" in RLS policies using Security Definer
-- =====================================================================

-- 1. CREATE SECURITY DEFINER HELPER
-- This function runs with owner privileges, bypassing RLS to check roles.
-- This is the standard "Big Tech" way to resolve recursion in PostgreSQL.
CREATE OR REPLACE FUNCTION public.check_is_admin() 
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
    AND (role = 'admin' OR role = 'manager')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. REFIX PROFILES POLICIES
-- Drop all potentially recursive policies
DROP POLICY IF EXISTS "Profiles are viewable by owner or admin" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

-- SELECT: User can see themselves, or an Admin can see everyone
CREATE POLICY "Profiles are viewable by owner or admin" ON public.profiles
FOR SELECT USING (
  auth.uid() = id OR check_is_admin()
);

-- INSERT: User can create their own profile (Onboarding)
-- Note: is_profile_complete should be checked if needed, but basic UID check is safe.
CREATE POLICY "Users can insert their own profile" ON public.profiles
FOR INSERT WITH CHECK (auth.uid() = id);

-- UPDATE: User can update their own profile
CREATE POLICY "Users can update their own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id);


-- 3. REFIX DAILY LOGS POLICIES
DROP POLICY IF EXISTS "Admins can oversee all logs" ON public.daily_logs;
DROP POLICY IF EXISTS "Logs are manageable by owner" ON public.daily_logs;

CREATE POLICY "Logs are manageable by owner" ON public.daily_logs
FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can oversee all logs" ON public.daily_logs
FOR SELECT USING (check_is_admin());


-- 4. REFIX AMAL TASKS POLICIES
DROP POLICY IF EXISTS "Institutional management can modify tasks" ON public.amal_tasks;
DROP POLICY IF EXISTS "Public tasks are viewable by all authenticated users" ON public.amal_tasks;

CREATE POLICY "Public tasks are viewable by all authenticated users" ON public.amal_tasks
FOR SELECT TO authenticated USING (is_active = true);

CREATE POLICY "Institutional management can modify tasks" ON public.amal_tasks
FOR ALL TO authenticated USING (check_is_admin());

-- 5. FINAL SYSTEM CHECK
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.amal_tasks ENABLE ROW LEVEL SECURITY;
