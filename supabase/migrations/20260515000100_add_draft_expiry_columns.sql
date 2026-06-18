-- Add draft expiry metadata to ordersmain for automatic draft expiration handling.
ALTER TABLE public.ordersmain
  ADD COLUMN IF NOT EXISTS draft_created_at timestamptz,
  ADD COLUMN IF NOT EXISTS draft_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS is_draft_expired boolean NOT NULL DEFAULT false;
