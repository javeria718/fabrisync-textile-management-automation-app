-- Rename legacy Abaya product and style values to Open/Closed
-- This migration keeps the existing dataset compatible with the new Abaya style cleanup.

UPDATE public.abaya_cost_config
SET abaya_type = 'Open Abaya'
WHERE abaya_type = 'Fancy Abaya';

UPDATE public.abaya_cost_config
SET abaya_type = 'Closed Abaya'
WHERE abaya_type = 'Casual Abaya';

UPDATE public.ordersmain
SET product_type = 'Open Abaya'
WHERE product_category = 'Abaya' AND product_type = 'Fancy Abaya';

UPDATE public.ordersmain
SET product_type = 'Closed Abaya'
WHERE product_category = 'Abaya' AND product_type = 'Casual Abaya';

UPDATE public.ordersmain
SET product_specifications = jsonb_set(
    product_specifications,
    '{style_type}',
    '"Open"',
    true
)
WHERE product_category = 'Abaya'
  AND product_specifications->> 'style_type' = 'Fancy';

UPDATE public.ordersmain
SET product_specifications = jsonb_set(
    product_specifications,
    '{style_type}',
    '"Closed"',
    true
)
WHERE product_category = 'Abaya'
  AND product_specifications->> 'style_type' = 'Casual';
