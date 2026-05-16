-- Create Abaya Cost Configuration Table
-- This table stores all abaya-specific pricing configurations
-- Separate from generic cost_master for modular, maintainable architecture

DROP TABLE IF EXISTS public.abaya_cost_config CASCADE;

CREATE TABLE public.abaya_cost_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Abaya configuration
    abaya_type VARCHAR(50) NOT NULL,
    fabric_type VARCHAR(50) NOT NULL,
    quality_grade VARCHAR(50) NOT NULL,

    -- Pricing configuration (PKR)
    base_labor_hours NUMERIC(6, 2) NOT NULL DEFAULT 1.20,
    fabric_rate NUMERIC(10, 2) NOT NULL DEFAULT 850.0,
    labor_multiplier NUMERIC(5, 2) NOT NULL DEFAULT 1.00,
    processing_rate NUMERIC(10, 2) NOT NULL DEFAULT 250.0,
    embellishment_cost NUMERIC(10, 2) NOT NULL DEFAULT 450.0,
    wastage_percent NUMERIC(5, 2) NOT NULL DEFAULT 5.0,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(abaya_type, fabric_type, quality_grade),
    CONSTRAINT positive_base_labor_hours CHECK (base_labor_hours >= 0),
    CONSTRAINT positive_fabric_rate CHECK (fabric_rate > 0),
    CONSTRAINT positive_labor_multiplier CHECK (labor_multiplier > 0),
    CONSTRAINT positive_processing_rate CHECK (processing_rate >= 0),
    CONSTRAINT positive_embellishment_cost CHECK (embellishment_cost >= 0),
    CONSTRAINT valid_wastage CHECK (wastage_percent >= 0 AND wastage_percent <= 100)
);

CREATE INDEX idx_abaya_type ON public.abaya_cost_config(abaya_type);
CREATE INDEX idx_abaya_fabric_type ON public.abaya_cost_config(fabric_type);
CREATE INDEX idx_abaya_quality_grade ON public.abaya_cost_config(quality_grade);
CREATE INDEX idx_abaya_lookup ON public.abaya_cost_config(abaya_type, fabric_type, quality_grade);
CREATE INDEX idx_abaya_updated_at ON public.abaya_cost_config(updated_at DESC);

ALTER TABLE public.abaya_cost_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read access"
    ON public.abaya_cost_config
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated admin access"
    ON public.abaya_cost_config
    FOR ALL
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'admin'
    );

INSERT INTO public.abaya_cost_config (
    abaya_type,
    fabric_type,
    quality_grade,
    base_labor_hours,
    fabric_rate,
    labor_multiplier,
    processing_rate,
    embellishment_cost,
    wastage_percent
) VALUES
    ('Closed Abaya', 'Nidha', 'Economy', 1.20, 850.0, 1.00, 250.0, 450.0, 5.0),
    ('Closed Abaya', 'Nidha', 'Standard', 1.20, 850.0, 1.15, 287.5, 450.0, 5.0),
    ('Closed Abaya', 'Nidha', 'Premium', 1.20, 850.0, 1.40, 337.5, 450.0, 5.0),
    ('Closed Abaya', 'Chiffon', 'Economy', 1.20, 1200.0, 1.35, 250.0, 450.0, 10.0),
    ('Closed Abaya', 'Chiffon', 'Standard', 1.20, 1200.0, 1.55, 287.5, 450.0, 10.0),
    ('Closed Abaya', 'Chiffon', 'Premium', 1.20, 1200.0, 1.89, 337.5, 450.0, 10.0),
    ('Closed Abaya', 'Georgette', 'Economy', 1.20, 1050.0, 1.20, 250.0, 450.0, 8.0),
    ('Closed Abaya', 'Georgette', 'Standard', 1.20, 1050.0, 1.38, 287.5, 450.0, 8.0),
    ('Closed Abaya', 'Georgette', 'Premium', 1.20, 1050.0, 1.68, 337.5, 450.0, 8.0),

    ('Open Abaya', 'Nidha', 'Economy', 2.00, 850.0, 1.40, 550.0, 450.0, 5.0),
    ('Open Abaya', 'Nidha', 'Standard', 2.00, 850.0, 1.61, 632.5, 450.0, 5.0),
    ('Open Abaya', 'Nidha', 'Premium', 2.00, 850.0, 1.96, 742.5, 450.0, 5.0),
    ('Open Abaya', 'Chiffon', 'Economy', 2.00, 1200.0, 1.89, 550.0, 450.0, 10.0),
    ('Open Abaya', 'Chiffon', 'Standard', 2.00, 1200.0, 2.18, 632.5, 450.0, 10.0),
    ('Open Abaya', 'Chiffon', 'Premium', 2.00, 1200.0, 2.49, 742.5, 450.0, 10.0),
    ('Open Abaya', 'Georgette', 'Economy', 2.00, 1050.0, 1.68, 550.0, 450.0, 8.0),
    ('Open Abaya', 'Georgette', 'Standard', 2.00, 1050.0, 1.92, 632.5, 450.0, 8.0),
    ('Open Abaya', 'Georgette', 'Premium', 2.00, 1050.0, 2.19, 742.5, 450.0, 8.0),

    ('Embroidered Abaya', 'Nidha', 'Economy', 3.00, 850.0, 1.80, 900.0, 450.0, 5.0),
    ('Embroidered Abaya', 'Nidha', 'Standard', 3.00, 850.0, 2.07, 1035.0, 450.0, 5.0),
    ('Embroidered Abaya', 'Nidha', 'Premium', 3.00, 850.0, 2.52, 1215.0, 450.0, 5.0),
    ('Embroidered Abaya', 'Chiffon', 'Economy', 3.00, 1200.0, 2.43, 900.0, 450.0, 10.0),
    ('Embroidered Abaya', 'Chiffon', 'Standard', 3.00, 1200.0, 2.78, 1035.0, 450.0, 10.0),
    ('Embroidered Abaya', 'Chiffon', 'Premium', 3.00, 1200.0, 3.10, 1215.0, 450.0, 10.0),
    ('Embroidered Abaya', 'Georgette', 'Economy', 3.00, 1050.0, 2.16, 900.0, 450.0, 8.0),
    ('Embroidered Abaya', 'Georgette', 'Standard', 3.00, 1050.0, 2.48, 1035.0, 450.0, 8.0),
    ('Embroidered Abaya', 'Georgette', 'Premium', 3.00, 1050.0, 2.80, 1215.0, 450.0, 8.0);

CREATE OR REPLACE FUNCTION update_abaya_cost_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER abaya_cost_config_timestamp
    BEFORE UPDATE ON public.abaya_cost_config
    FOR EACH ROW
    EXECUTE FUNCTION update_abaya_cost_config_timestamp();

GRANT SELECT ON public.abaya_cost_config TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.abaya_cost_config TO authenticated;
