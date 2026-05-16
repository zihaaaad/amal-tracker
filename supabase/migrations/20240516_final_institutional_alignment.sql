-- =====================================================================
-- AS-SUNNAH FOUNDATION TRACKER: FINAL INSTITUTIONAL ALIGNMENT
-- Version: 1.4
-- Purpose: Final security hardening, task management RBAC, and performance
-- =====================================================================

-- 1. HARDEING TASK POLICIES
-- Enabling RLS for the tasks definition table
ALTER TABLE public.amal_tasks ENABLE ROW LEVEL SECURITY;

-- Drop legacy if exists
DROP POLICY IF EXISTS "Institutional management can modify tasks" ON public.amal_tasks;
DROP POLICY IF EXISTS "Public tasks are viewable by all authenticated users" ON public.amal_tasks;

-- Policy: Authenticated users can view active tasks
CREATE POLICY "Public tasks are viewable by all authenticated users" ON public.amal_tasks
FOR SELECT TO authenticated USING (is_active = true);

-- Policy: Only Admins and Managers can perform DML (Insert/Update/Delete)
CREATE POLICY "Institutional management can modify tasks" ON public.amal_tasks
FOR ALL TO authenticated USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'manager')
);

-- 2. PERFORMANCE OPTIMIZATION INDEXES
-- Indexing roles for faster RBAC checks in policies
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- GIN index for the JSONB completion data to allow deep querying of spiritual trends
CREATE INDEX IF NOT EXISTS idx_logs_completion_data ON public.daily_logs USING gin(completion_data);

-- 3. SCHEMA INTEGRITY & DEFAULTS
-- Ensure every profile defaults to 'employee' if not specified
ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'employee';

-- Ensure sub_institute is tracked for institutional routing
ALTER TABLE public.profiles ALTER COLUMN sub_institute SET DEFAULT 'Main Branch';

-- 4. CLEANUP LEGACY CONSTRAINTS
-- Ensuring the user_id foreign key in daily_logs points to the Profile table (not just auth.users)
-- for better data integrity and easier JOINs in analytics views.
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'daily_logs_user_id_fkey') THEN
    ALTER TABLE public.daily_logs DROP CONSTRAINT daily_logs_user_id_fkey;
  END IF;
END $$;

ALTER TABLE public.daily_logs 
  ADD CONSTRAINT daily_logs_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 5. RE-VALIDATE ANALYTICS VIEW
CREATE OR REPLACE VIEW public.view_department_analytics AS
SELECT 
    p.department,
    p.sub_institute,
    COUNT(DISTINCT p.id) as total_employees,
    COUNT(l.id) as total_logs_filled,
    DATE_TRUNC('month', l.date) as log_month
FROM public.profiles p
LEFT JOIN public.daily_logs l ON p.id = l.user_id
GROUP BY p.department, p.sub_institute, DATE_TRUNC('month', l.date);

GRANT SELECT ON public.view_department_analytics TO authenticated;
