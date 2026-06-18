-- Restore Abaya product and style labels after the incorrect Open/Closed product refactor.
-- Product type must remain Fancy Abaya / Casual Abaya / Embroidered Abaya.
-- Style type should be stored as Open Abaya / Closed Abaya.

UPDATE public.ordersmain
SET product_type = 'Fancy Abaya'
WHERE product_category = 'Abaya' AND product_type = 'Open Abaya';

UPDATE public.ordersmain
SET product_type = 'Casual Abaya'
WHERE product_category = 'Abaya' AND product_type = 'Closed Abaya';

UPDATE public.ordersmain
SET product_specifications = jsonb_set(
    product_specifications,
    '{style_type}',
    '"Open Abaya"',
    true
)
WHERE product_category = 'Abaya'
  AND product_specifications->> 'style_type' IN ('Open', 'Fancy');

UPDATE public.ordersmain
SET product_specifications = jsonb_set(
    product_specifications,
    '{style_type}',
    '"Closed Abaya"',
    true
)
WHERE product_category = 'Abaya'
  AND product_specifications->> 'style_type' IN ('Closed', 'Casual');
