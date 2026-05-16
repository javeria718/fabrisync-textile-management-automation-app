-- Comprehensive migration to ensure ordersmain has all required columns.
-- This migration is idempotent and safe to run multiple times.
-- It adds any missing columns from previous migrations.

BEGIN;

-- Ensure all columns from the upgrade_order_module migration
ALTER TABLE public.ordersmain
  ADD COLUMN IF NOT EXISTS product_category text,
  ADD COLUMN IF NOT EXISTS product_type text,
  ADD COLUMN IF NOT EXISTS product_specifications jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS required_delivery_date date,
  ADD COLUMN IF NOT EXISTS quality_grade text,
  ADD COLUMN IF NOT EXISTS priority text DEFAULT 'Normal',
  ADD COLUMN IF NOT EXISTS special_instructions text,
  ADD COLUMN IF NOT EXISTS custom_packaging boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS branding_required boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS estimated_production_hours numeric,
  ADD COLUMN IF NOT EXISTS estimated_production_days numeric;

-- Ensure draft expiry columns exist
ALTER TABLE public.ordersmain
  ADD COLUMN IF NOT EXISTS draft_created_at timestamptz,
  ADD COLUMN IF NOT EXISTS draft_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS is_draft_expired boolean NOT NULL DEFAULT false;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_ordersmain_product_category
  ON public.ordersmain (product_category);

CREATE INDEX IF NOT EXISTS idx_ordersmain_product_type
  ON public.ordersmain (product_type);

CREATE INDEX IF NOT EXISTS idx_ordersmain_required_delivery_date
  ON public.ordersmain (required_delivery_date);

CREATE INDEX IF NOT EXISTS idx_ordersmain_priority
  ON public.ordersmain (priority);

CREATE INDEX IF NOT EXISTS idx_ordersmain_status
  ON public.ordersmain (status);

CREATE INDEX IF NOT EXISTS idx_ordersmain_draft_created_at
  ON public.ordersmain (draft_created_at)
  WHERE status = 'draft';

COMMIT;
