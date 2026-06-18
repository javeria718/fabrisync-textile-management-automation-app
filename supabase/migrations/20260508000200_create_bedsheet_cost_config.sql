-- Create Bedsheet Cost Configuration Table
-- This table stores all bedsheet-specific pricing configurations
-- Separate from generic cost_master for modular architecture

DROP TABLE IF EXISTS public.bedsheet_cost_config CASCADE;

CREATE TABLE public.bedsheet_cost_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    bedsheet_type VARCHAR(50) NOT NULL,
    fabric_type VARCHAR(50) NOT NULL,
    bed_size VARCHAR(50) NOT NULL,
    quality_grade VARCHAR(50) NOT NULL,

    base_labor_hours NUMERIC(6, 2) NOT NULL DEFAULT 0.80,
    material_rate NUMERIC(10, 2) NOT NULL DEFAULT 650.00,
    labor_multiplier NUMERIC(5, 2) NOT NULL DEFAULT 1.00,
    processing_rate NUMERIC(10, 2) NOT NULL DEFAULT 180.00,
    printing_charge NUMERIC(10, 2) NOT NULL DEFAULT 850.00,
    wastage_percent NUMERIC(5, 2) NOT NULL DEFAULT 5.00,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(bedsheet_type, fabric_type, bed_size, quality_grade),
    CONSTRAINT positive_base_labor_hours CHECK (base_labor_hours >= 0),
    CONSTRAINT positive_material_rate CHECK (material_rate > 0),
    CONSTRAINT positive_labor_multiplier CHECK (labor_multiplier > 0),
    CONSTRAINT positive_processing_rate CHECK (processing_rate >= 0),
    CONSTRAINT positive_printing_charge CHECK (printing_charge >= 0),
    CONSTRAINT valid_wastage CHECK (wastage_percent >= 0 AND wastage_percent <= 100)
);

CREATE INDEX idx_bedsheet_type ON public.bedsheet_cost_config(bedsheet_type);
CREATE INDEX idx_bedsheet_fabric_type ON public.bedsheet_cost_config(fabric_type);
CREATE INDEX idx_bedsheet_bed_size ON public.bedsheet_cost_config(bed_size);
CREATE INDEX idx_bedsheet_quality_grade ON public.bedsheet_cost_config(quality_grade);
CREATE INDEX idx_bedsheet_lookup ON public.bedsheet_cost_config(bedsheet_type, fabric_type, bed_size, quality_grade);
CREATE INDEX idx_bedsheet_updated_at ON public.bedsheet_cost_config(updated_at DESC);

ALTER TABLE public.bedsheet_cost_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read access"
    ON public.bedsheet_cost_config
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated admin access"
    ON public.bedsheet_cost_config
    FOR ALL
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'admin'
    );

INSERT INTO public.bedsheet_cost_config (
    bedsheet_type,
    fabric_type,
    bed_size,
    quality_grade,
    base_labor_hours,
    material_rate,
    labor_multiplier,
    processing_rate,
    printing_charge,
    wastage_percent
) VALUES
    ('Flat Sheet', 'Cotton', 'Single', 'Economy', 0.80, 650.0, 1.00, 180.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Single', 'Standard', 0.80, 650.0, 1.15, 207.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Single', 'Premium', 0.80, 650.0, 1.40, 270.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Double', 'Economy', 0.80, 650.0, 1.00, 180.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Double', 'Standard', 0.80, 650.0, 1.15, 207.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Double', 'Premium', 0.80, 650.0, 1.40, 270.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Queen', 'Economy', 0.80, 650.0, 1.00, 180.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Queen', 'Standard', 0.80, 650.0, 1.15, 207.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'Queen', 'Premium', 0.80, 650.0, 1.40, 270.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'King', 'Economy', 0.80, 650.0, 1.00, 180.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'King', 'Standard', 0.80, 650.0, 1.15, 207.0, 850.0, 5.0),
    ('Flat Sheet', 'Cotton', 'King', 'Premium', 0.80, 650.0, 1.40, 270.0, 850.0, 5.0),

    ('Flat Sheet', 'Blend', 'Single', 'Economy', 0.80, 850.0, 1.15, 207.0, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Single', 'Standard', 0.80, 850.0, 1.32, 238.05, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Single', 'Premium', 0.80, 850.0, 1.61, 310.50, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Double', 'Economy', 0.80, 850.0, 1.15, 207.0, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Double', 'Standard', 0.80, 850.0, 1.32, 238.05, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Double', 'Premium', 0.80, 850.0, 1.61, 310.50, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Queen', 'Economy', 0.80, 850.0, 1.15, 207.0, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Queen', 'Standard', 0.80, 850.0, 1.32, 238.05, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'Queen', 'Premium', 0.80, 850.0, 1.61, 310.50, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'King', 'Economy', 0.80, 850.0, 1.15, 207.0, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'King', 'Standard', 0.80, 850.0, 1.32, 238.05, 850.0, 7.0),
    ('Flat Sheet', 'Blend', 'King', 'Premium', 0.80, 850.0, 1.61, 310.50, 850.0, 7.0),

    ('Flat Sheet', 'Silk', 'Single', 'Economy', 0.80, 1600.0, 1.60, 270.0, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Single', 'Standard', 0.80, 1600.0, 1.84, 310.50, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Single', 'Premium', 0.80, 1600.0, 2.24, 405.00, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Double', 'Economy', 0.80, 1600.0, 1.60, 270.0, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Double', 'Standard', 0.80, 1600.0, 1.84, 310.50, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Double', 'Premium', 0.80, 1600.0, 2.24, 405.00, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Queen', 'Economy', 0.80, 1600.0, 1.60, 270.0, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Queen', 'Standard', 0.80, 1600.0, 1.84, 310.50, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'Queen', 'Premium', 0.80, 1600.0, 2.24, 405.00, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'King', 'Economy', 0.80, 1600.0, 1.60, 270.0, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'King', 'Standard', 0.80, 1600.0, 1.84, 310.50, 850.0, 12.0),
    ('Flat Sheet', 'Silk', 'King', 'Premium', 0.80, 1600.0, 2.24, 405.00, 850.0, 12.0),

    ('Fitted Sheet', 'Cotton', 'Single', 'Economy', 1.50, 650.0, 1.50, 450.0, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Single', 'Standard', 1.50, 650.0, 1.72, 517.5, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Single', 'Premium', 1.50, 650.0, 2.10, 675.0, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Double', 'Economy', 1.50, 650.0, 1.50, 450.0, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Double', 'Standard', 1.50, 650.0, 1.72, 517.5, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Double', 'Premium', 1.50, 650.0, 2.10, 675.0, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Queen', 'Economy', 1.50, 650.0, 1.50, 450.0, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Queen', 'Standard', 1.50, 650.0, 1.72, 517.5, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'Queen', 'Premium', 1.50, 650.0, 2.10, 675.0, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'King', 'Economy', 1.50, 650.0, 1.50, 450.0, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'King', 'Standard', 1.50, 650.0, 1.72, 517.5, 850.0, 5.0),
    ('Fitted Sheet', 'Cotton', 'King', 'Premium', 1.50, 650.0, 2.10, 675.0, 850.0, 5.0),

    ('Fitted Sheet', 'Blend', 'Single', 'Economy', 1.50, 850.0, 1.73, 517.5, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Single', 'Standard', 1.50, 850.0, 1.99, 594.75, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Single', 'Premium', 1.50, 850.0, 2.41, 742.50, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Double', 'Economy', 1.50, 850.0, 1.73, 517.5, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Double', 'Standard', 1.50, 850.0, 1.99, 594.75, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Double', 'Premium', 1.50, 850.0, 2.41, 742.50, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Queen', 'Economy', 1.50, 850.0, 1.73, 517.5, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Queen', 'Standard', 1.50, 850.0, 1.99, 594.75, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'Queen', 'Premium', 1.50, 850.0, 2.41, 742.50, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'King', 'Economy', 1.50, 850.0, 1.73, 517.5, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'King', 'Standard', 1.50, 850.0, 1.99, 594.75, 850.0, 7.0),
    ('Fitted Sheet', 'Blend', 'King', 'Premium', 1.50, 850.0, 2.41, 742.50, 850.0, 7.0),

    ('Fitted Sheet', 'Silk', 'Single', 'Economy', 1.50, 1600.0, 2.40, 675.0, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Single', 'Standard', 1.50, 1600.0, 2.76, 776.25, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Single', 'Premium', 1.50, 1600.0, 3.36, 982.50, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Double', 'Economy', 1.50, 1600.0, 2.40, 675.0, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Double', 'Standard', 1.50, 1600.0, 2.76, 776.25, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Double', 'Premium', 1.50, 1600.0, 3.36, 982.50, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Queen', 'Economy', 1.50, 1600.0, 2.40, 675.0, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Queen', 'Standard', 1.50, 1600.0, 2.76, 776.25, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'Queen', 'Premium', 1.50, 1600.0, 3.36, 982.50, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'King', 'Economy', 1.50, 1600.0, 2.40, 675.0, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'King', 'Standard', 1.50, 1600.0, 2.76, 776.25, 850.0, 12.0),
    ('Fitted Sheet', 'Silk', 'King', 'Premium', 1.50, 1600.0, 3.36, 982.50, 850.0, 12.0),

    ('Pillow Cover Set', 'Cotton', 'Single', 'Economy', 0.50, 650.0, 0.80, 120.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Single', 'Standard', 0.50, 650.0, 0.92, 138.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Single', 'Premium', 0.50, 650.0, 1.12, 180.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Double', 'Economy', 0.50, 650.0, 0.80, 120.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Double', 'Standard', 0.50, 650.0, 0.92, 138.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Double', 'Premium', 0.50, 650.0, 1.12, 180.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Queen', 'Economy', 0.50, 650.0, 0.80, 120.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Queen', 'Standard', 0.50, 650.0, 0.92, 138.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'Queen', 'Premium', 0.50, 650.0, 1.12, 180.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'King', 'Economy', 0.50, 650.0, 0.80, 120.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'King', 'Standard', 0.50, 650.0, 0.92, 138.0, 850.0, 5.0),
    ('Pillow Cover Set', 'Cotton', 'King', 'Premium', 0.50, 650.0, 1.12, 180.0, 850.0, 5.0),

    ('Pillow Cover Set', 'Blend', 'Single', 'Economy', 0.50, 850.0, 0.92, 138.0, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Single', 'Standard', 0.50, 850.0, 1.06, 158.7, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Single', 'Premium', 0.50, 850.0, 1.29, 207.0, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Double', 'Economy', 0.50, 850.0, 0.92, 138.0, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Double', 'Standard', 0.50, 850.0, 1.06, 158.7, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Double', 'Premium', 0.50, 850.0, 1.29, 207.0, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Queen', 'Economy', 0.50, 850.0, 0.92, 138.0, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Queen', 'Standard', 0.50, 850.0, 1.06, 158.7, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'Queen', 'Premium', 0.50, 850.0, 1.29, 207.0, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'King', 'Economy', 0.50, 850.0, 0.92, 138.0, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'King', 'Standard', 0.50, 850.0, 1.06, 158.7, 850.0, 7.0),
    ('Pillow Cover Set', 'Blend', 'King', 'Premium', 0.50, 850.0, 1.29, 207.0, 850.0, 7.0),

    ('Pillow Cover Set', 'Silk', 'Single', 'Economy', 0.50, 1600.0, 1.28, 192.0, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Single', 'Standard', 0.50, 1600.0, 1.47, 220.5, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Single', 'Premium', 0.50, 1600.0, 1.79, 268.8, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Double', 'Economy', 0.50, 1600.0, 1.28, 192.0, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Double', 'Standard', 0.50, 1600.0, 1.47, 220.5, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Double', 'Premium', 0.50, 1600.0, 1.79, 268.8, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Queen', 'Economy', 0.50, 1600.0, 1.28, 192.0, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Queen', 'Standard', 0.50, 1600.0, 1.47, 220.5, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'Queen', 'Premium', 0.50, 1600.0, 1.79, 268.8, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'King', 'Economy', 0.50, 1600.0, 1.28, 192.0, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'King', 'Standard', 0.50, 1600.0, 1.47, 220.5, 850.0, 12.0),
    ('Pillow Cover Set', 'Silk', 'King', 'Premium', 0.50, 1600.0, 1.79, 268.8, 850.0, 12.0);

CREATE OR REPLACE FUNCTION update_bedsheet_cost_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER bedsheet_cost_config_timestamp
    BEFORE UPDATE ON public.bedsheet_cost_config
    FOR EACH ROW
    EXECUTE FUNCTION update_bedsheet_cost_config_timestamp();

GRANT SELECT ON public.bedsheet_cost_config TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.bedsheet_cost_config TO authenticated;
