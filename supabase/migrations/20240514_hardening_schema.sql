-- =====================================================================
-- AS-SUNNAH FOUNDATION TRACKER: HARDENING SCHEMA
-- Version: 1.2
-- Purpose: Standardizing column names and expanding task metadata
-- =====================================================================

-- 1. RENAME COLUMN IN DAILY_LOGS
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_logs' AND column_name = 'values') THEN
    ALTER TABLE public.daily_logs RENAME COLUMN "values" TO completion_data;
  END IF;
END $$;

-- 2. EXPAND AMAL_TASKS METADATA
ALTER TABLE public.amal_tasks 
  ADD COLUMN IF NOT EXISTS subtitle TEXT,
  ADD COLUMN IF NOT EXISTS frequency TEXT DEFAULT 'daily',
  ADD COLUMN IF NOT EXISTS active_days INTEGER[],
  ADD COLUMN IF NOT EXISTS icon_code TEXT,
  ADD COLUMN IF NOT EXISTS color_value BIGINT;

-- 3. UPDATE ANALYTICS VIEW FOR NEW COLUMN NAME
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

-- 4. SEED DATA ENHANCEMENT
-- Adding institutional tasks with proper metadata
INSERT INTO public.amal_tasks (id, title, subtitle, category, points, frequency, icon_code, color_value) VALUES
('morning_adhkar', 'Morning Adhkar', 'Complete before sunrise', 'spiritual', 3, 'daily', '984365', 4282501089),
('evening_adhkar', 'Evening Adhkar', 'Complete before maghrib', 'spiritual', 3, 'daily', '984365', 4294939392),
('office_cleanliness', 'Workspace Cleanliness', 'Maintain a professional desk', 'professional', 2, 'daily', '984401', 4280523008),
('weekly_foundation_meeting', 'Foundation Meeting', 'Attend weekly strategy session', 'professional', 5, 'weekly', '984422', 4283215696)
ON CONFLICT (id) DO UPDATE SET
  subtitle = EXCLUDED.subtitle,
  points = EXCLUDED.points,
  frequency = EXCLUDED.frequency,
  icon_code = EXCLUDED.icon_code,
  color_value = EXCLUDED.color_value;
