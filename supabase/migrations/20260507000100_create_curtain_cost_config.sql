-- Create Curtain Cost Configuration Table
-- This table stores all curtain-specific pricing configurations
-- Separate from generic cost_master for modular, maintainable architecture

-- Drop if exists (for safe re-runs)
DROP TABLE IF EXISTS public.curtain_cost_config CASCADE;

-- Create the curtain_cost_config table
CREATE TABLE public.curtain_cost_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Curtain Specifications
    curtain_type VARCHAR(50) NOT NULL,
    fabric_type VARCHAR(50) NOT NULL,
    header_style VARCHAR(50) NOT NULL,
    
    -- Pricing Configuration (PKR - Pakistani Rupees)
    material_rate NUMERIC(10, 2) NOT NULL DEFAULT 450.0,
    labor_multiplier NUMERIC(5, 2) NOT NULL DEFAULT 1.0,
    complexity_multiplier NUMERIC(5, 2) NOT NULL DEFAULT 1.0,
    base_labor_hours NUMERIC(6, 2) NOT NULL DEFAULT 0.8,
    processing_cost NUMERIC(10, 2) NOT NULL DEFAULT 200.0,
    wastage_percent NUMERIC(5, 2) NOT NULL DEFAULT 5.0,
    
    -- Audit Fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure unique combination of curtain type, fabric type, and header style
    UNIQUE(curtain_type, fabric_type, header_style),
    
    -- Data validation constraints
    CONSTRAINT positive_material_rate CHECK (material_rate > 0),
    CONSTRAINT positive_labor_multiplier CHECK (labor_multiplier > 0),
    CONSTRAINT positive_complexity CHECK (complexity_multiplier > 0),
    CONSTRAINT positive_labor_hours CHECK (base_labor_hours >= 0),
    CONSTRAINT positive_processing CHECK (processing_cost >= 0),
    CONSTRAINT valid_wastage CHECK (wastage_percent >= 0 AND wastage_percent <= 100)
);

-- Create indexes for common queries
CREATE INDEX idx_curtain_type ON public.curtain_cost_config(curtain_type);
CREATE INDEX idx_fabric_type ON public.curtain_cost_config(fabric_type);
CREATE INDEX idx_header_style ON public.curtain_cost_config(header_style);
CREATE INDEX idx_curtain_lookup ON public.curtain_cost_config(curtain_type, fabric_type, header_style);
CREATE INDEX idx_updated_at ON public.curtain_cost_config(updated_at DESC);

-- Enable Row Level Security
ALTER TABLE public.curtain_cost_config ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read (select)
CREATE POLICY "Allow authenticated read access"
    ON public.curtain_cost_config
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow authenticated admins to insert/update/delete
CREATE POLICY "Allow authenticated admin access"
    ON public.curtain_cost_config
    FOR ALL
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'admin'
    );

-- Seed data: Realistic curtain cost configurations for all combinations
INSERT INTO public.curtain_cost_config (
    curtain_type, fabric_type, header_style,
    material_rate, labor_multiplier, complexity_multiplier,
    base_labor_hours, processing_cost, wastage_percent
) VALUES
    -- Window Curtain + Sheer
    ('Window Curtain', 'Sheer', 'Pleated', 450.0, 1.00, 1.15, 0.80, 200.0, 5.0),
    ('Window Curtain', 'Sheer', 'Eyelet', 450.0, 1.00, 1.20, 0.80, 200.0, 5.0),
    ('Window Curtain', 'Sheer', 'Rod Pocket', 450.0, 1.00, 1.05, 0.80, 200.0, 5.0),
    
    -- Window Curtain + Blackout
    ('Window Curtain', 'Blackout', 'Pleated', 850.0, 1.25, 1.15, 0.80, 200.0, 10.0),
    ('Window Curtain', 'Blackout', 'Eyelet', 850.0, 1.25, 1.20, 0.80, 200.0, 10.0),
    ('Window Curtain', 'Blackout', 'Rod Pocket', 850.0, 1.25, 1.05, 0.80, 200.0, 10.0),
    
    -- Window Curtain + Thermal
    ('Window Curtain', 'Thermal', 'Pleated', 1200.0, 1.45, 1.15, 0.80, 200.0, 12.0),
    ('Window Curtain', 'Thermal', 'Eyelet', 1200.0, 1.45, 1.20, 0.80, 200.0, 12.0),
    ('Window Curtain', 'Thermal', 'Rod Pocket', 1200.0, 1.45, 1.05, 0.80, 200.0, 12.0),
    
    -- Door Curtain + Sheer
    ('Door Curtain', 'Sheer', 'Pleated', 450.0, 1.00, 1.32, 1.00, 300.0, 5.0),
    ('Door Curtain', 'Sheer', 'Eyelet', 450.0, 1.00, 1.38, 1.00, 300.0, 5.0),
    ('Door Curtain', 'Sheer', 'Rod Pocket', 450.0, 1.00, 1.21, 1.00, 300.0, 5.0),
    
    -- Door Curtain + Blackout
    ('Door Curtain', 'Blackout', 'Pleated', 850.0, 1.25, 1.32, 1.00, 300.0, 10.0),
    ('Door Curtain', 'Blackout', 'Eyelet', 850.0, 1.25, 1.38, 1.00, 300.0, 10.0),
    ('Door Curtain', 'Blackout', 'Rod Pocket', 850.0, 1.25, 1.21, 1.00, 300.0, 10.0),
    
    -- Door Curtain + Thermal
    ('Door Curtain', 'Thermal', 'Pleated', 1200.0, 1.45, 1.32, 1.00, 300.0, 12.0),
    ('Door Curtain', 'Thermal', 'Eyelet', 1200.0, 1.45, 1.38, 1.00, 300.0, 12.0),
    ('Door Curtain', 'Thermal', 'Rod Pocket', 1200.0, 1.45, 1.21, 1.00, 300.0, 12.0),
    
    -- Blackout Curtain + Sheer (unusual but valid)
    ('Blackout Curtain', 'Sheer', 'Pleated', 450.0, 1.00, 1.61, 1.50, 600.0, 5.0),
    ('Blackout Curtain', 'Sheer', 'Eyelet', 450.0, 1.00, 1.68, 1.50, 600.0, 5.0),
    ('Blackout Curtain', 'Sheer', 'Rod Pocket', 450.0, 1.00, 1.47, 1.50, 600.0, 5.0),
    
    -- Blackout Curtain + Blackout
    ('Blackout Curtain', 'Blackout', 'Pleated', 850.0, 1.25, 1.61, 1.50, 600.0, 10.0),
    ('Blackout Curtain', 'Blackout', 'Eyelet', 850.0, 1.25, 1.68, 1.50, 600.0, 10.0),
    ('Blackout Curtain', 'Blackout', 'Rod Pocket', 850.0, 1.25, 1.47, 1.50, 600.0, 10.0),
    
    -- Blackout Curtain + Thermal
    ('Blackout Curtain', 'Thermal', 'Pleated', 1200.0, 1.45, 1.61, 1.50, 600.0, 12.0),
    ('Blackout Curtain', 'Thermal', 'Eyelet', 1200.0, 1.45, 1.68, 1.50, 600.0, 12.0),
    ('Blackout Curtain', 'Thermal', 'Rod Pocket', 1200.0, 1.45, 1.47, 1.50, 600.0, 12.0),
    
    -- Decorative Curtain + Sheer
    ('Decorative Curtain', 'Sheer', 'Pleated', 450.0, 1.00, 1.84, 1.80, 850.0, 5.0),
    ('Decorative Curtain', 'Sheer', 'Eyelet', 450.0, 1.00, 1.92, 1.80, 850.0, 5.0),
    ('Decorative Curtain', 'Sheer', 'Rod Pocket', 450.0, 1.00, 1.68, 1.80, 850.0, 5.0),
    
    -- Decorative Curtain + Blackout
    ('Decorative Curtain', 'Blackout', 'Pleated', 850.0, 1.25, 1.84, 1.80, 850.0, 10.0),
    ('Decorative Curtain', 'Blackout', 'Eyelet', 850.0, 1.25, 1.92, 1.80, 850.0, 10.0),
    ('Decorative Curtain', 'Blackout', 'Rod Pocket', 850.0, 1.25, 1.68, 1.80, 850.0, 10.0),
    
    -- Decorative Curtain + Thermal
    ('Decorative Curtain', 'Thermal', 'Pleated', 1200.0, 1.45, 1.84, 1.80, 850.0, 12.0),
    ('Decorative Curtain', 'Thermal', 'Eyelet', 1200.0, 1.45, 1.92, 1.80, 850.0, 12.0),
    ('Decorative Curtain', 'Thermal', 'Rod Pocket', 1200.0, 1.45, 1.68, 1.80, 850.0, 12.0);

-- Create audit trigger for updated_at
CREATE OR REPLACE FUNCTION update_curtain_cost_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER curtain_cost_config_timestamp
    BEFORE UPDATE ON public.curtain_cost_config
    FOR EACH ROW
    EXECUTE FUNCTION update_curtain_cost_config_timestamp();

-- Grant appropriate permissions
GRANT SELECT ON public.curtain_cost_config TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.curtain_cost_config TO authenticated;
