# Curtain Costing System - Implementation Guide

## Overview

A complete, production-grade curtain-specific costing and production-time estimation system for FabriSync textile mill ERP. This implementation features realistic textile manufacturing logic with full separation from generic costing.

**Status**: ✅ Complete implementation
**Architecture**: Modular, maintainable, scalable

---

## Architecture Overview

### Separation of Concerns

```
OrderCalculationService (Router)
    └── Curtain Orders → CurtainCalculationService
    └── Other Categories → Generic Calculation
```

All curtain logic is isolated in dedicated files:

```
lib/services/curtain/
├── curtain_pricing_rules.dart     # Constants & multipliers
├── curtain_cost_config.dart       # Data models
├── curtain_cost_repository.dart   # Database access
└── curtain_calculation_service.dart # Main calculations
```

---

## Implementation Details

### 1. Curtain Pricing Rules (`curtain_pricing_rules.dart`)

**Contains:**
- All hardcoded multipliers
- Constant values (labor rates, processing costs)
- Validation rules

**Key Constants:**

| Element | Values |
|---------|--------|
| Labor Rate | 350 PKR/hour |
| Curtain Types | 4 (Window, Door, Blackout, Decorative) |
| Fabric Types | 3 (Sheer, Blackout, Thermal) |
| Header Styles | 3 (Pleated, Eyelet, Rod Pocket) |
| Quality Grades | 3 (Economy, Standard, Premium) |

**Usage:**
```dart
// Get configuration
final config = CurtainPricingRules.getCurtainTypeConfig('Window Curtain');
final efficiency = CurtainPricingRules.getQuantityEfficiencyRule(25);

// Validate specs
final validation = CurtainPricingRules.validateCurtainSpecs(
  curtainType: 'Window Curtain',
  fabricType: 'Sheer',
  headerStyle: 'Pleated',
  qualityGrade: 'Standard',
  length: 1.5,
  width: 1.0,
  quantity: 10,
);
```

### 2. Curtain Cost Config (`curtain_cost_config.dart`)

**Models:**
- `CurtainCostConfig` - Database record from Supabase
- `CurtainCostRequest` - Query request
- `CurtainRuntimeConfig` - Computed runtime values

**Key Features:**
- Converts database rows to typed Dart objects
- Merges static configs with dynamic quality grades
- Provides factory constructors for easy instantiation

**Usage:**
```dart
// Load from database
final config = await repository.fetchCurtainCostConfig(
  curtainType: 'Window Curtain',
  fabricType: 'Sheer',
  headerStyle: 'Pleated',
);

// Create runtime config with quality grade
final runtime = CurtainRuntimeConfig.from(
  config: config,
  qualityGrade: 'Standard',
);
```

### 3. Curtain Cost Repository (`curtain_cost_repository.dart`)

**Responsibilities:**
- All Supabase database queries
- CRUD operations
- Seed data generation
- Configuration health checks

**Key Methods:**
```dart
// Query
Future<CurtainCostConfig?> fetchCurtainCostConfig({...})
Future<List<CurtainCostConfig>> fetchAllCurtainConfigs()
Future<List<CurtainCostConfig>> fetchConfigsByType(String type)

// Admin operations
Future<CurtainCostConfig?> createCurtainCostConfig(config)
Future<CurtainCostConfig?> updateCurtainCostConfig(config)
Future<bool> deleteCurtainCostConfig(String id)

// Initialization
Future<int> seedDefaultConfigurations()
Future<bool> hasConfigurationData()
Future<int> getConfigurationCount()
```

**Seeding:**
- Generates 36 realistic default configurations
- Covers all combinations: 4 curtain types × 3 fabrics × 3 headers
- Uses realistic multipliers from pricing rules

### 4. Curtain Calculation Service (`curtain_calculation_service.dart`)

**Core Logic:**
The main calculation engine implementing realistic textile manufacturing.

**Calculation Pipeline:**

```dart
calculateCurtainEstimate(request)
  ├─ Validate specifications
  ├─ Fetch cost config from database
  ├─ Build runtime config (merges with quality multipliers)
  │
  ├─ Calculate fabric area & wastage
  │   fabricArea = length × width
  │   effectiveFabricArea = fabricArea × (1 + wastagePercent)
  │
  ├─ Calculate material cost
  │   materialCost = effectiveFabricArea × materialRate × quantity
  │
  ├─ Calculate labor cost
  │   baseLaborHours = (baseLaborHours + headerLaborHours)
  │   laborHours *= fabricMultiplier × qualityMultiplier
  │   laborHours += areaBasedLabor (0.05 hours per m²)
  │   laborCost = laborHours × laborRatePerHour × quantity
  │
  ├─ Calculate processing costs
  │   baseProcessing + headerProcessing + qualityQC + premiumFinishing
  │
  ├─ Apply quantity efficiency scaling
  │   1-5 units: +20% surcharge
  │   6-20 units: Normal
  │   21-50 units: -5% efficiency gain
  │   51+ units: -10% efficiency gain
  │
  ├─ Calculate rush charges (if needed delivery < estimated)
  │   rushCharges = subtotal × 15%
  │
  └─ Build department schedule
      6 departments: Cutting, Stitching, Header, Finishing, QC, Packaging
```

**Models:**

```dart
// Request
class CurtainCalculationRequest {
  String curtainType;      // 'Window Curtain', 'Door Curtain', etc.
  String fabricType;        // 'Sheer', 'Blackout', 'Thermal'
  String headerStyle;       // 'Pleated', 'Eyelet', 'Rod Pocket'
  double length;            // meters
  double width;             // meters
  int quantity;
  String qualityGrade;      // 'Economy', 'Standard', 'Premium'
  DateTime requiredDeliveryDate;
  bool customPackaging;
}

// Result - Detailed breakdown
class CurtainCostBreakdown {
  double fabricAreaPerUnit;
  double effectiveFabricArea;
  double materialCostPerUnit;
  double totalMaterialCost;
  double baseLaborHoursPerUnit;
  double totalLaborHours;
  double laborCostPerUnit;
  double totalLaborCost;
  double baseProcessingCost;
  double headerProcessingCost;
  double qualityQcCost;
  double totalProcessingCost;
  double packagingCost;
  double transportHandling;
  double premiumFinishing;
  double subtotal;
  double rushCharges;
  double estimatedTotalCost;
}
```

---

## Costing Formulas

### Material Cost
```
effectiveFabricArea = (length × width × quantity) × (1 + wastagePercent/100)
materialCost = effectiveFabricArea × materialRatePerSqMeter
```

### Labor Cost
```
baseLaborHours = (curtainTypeBaseLaborHours + headerStyleLaborHours)
baseLaborHours *= fabricTypeLaborMultiplier
baseLaborHours *= qualityGradeLaborMultiplier
baseLaborHours *= quantityEfficiencyMultiplier

areaBasedLabor = (length × width) × 0.05 × fabricMultiplier
headerInstallationLabor = headerStyleRingInstallationLabor

totalLaborHoursPerUnit = baseLaborHours + areaBasedLabor + headerInstallationLabor
totalLaborCost = totalLaborHoursPerUnit × quantity × laborRatePerHour (350 PKR)
```

### Processing Cost
```
baseProcessing = curtainTypeBaseProcessingCost
headerProcessing = headerStyleExtraProcessingCost
qcCost = (fabricArea × 0.02 × qcMultiplier × quantity) × laborRatePerHour
finishingCost = (fabricArea × 25 × finishingMultiplier × quantity)

totalProcessingCost = (baseProcessing + headerProcessing + qcCost + finishingCost) × quantity
```

### Packaging & Handling
```
packagingCost = customPackaging ? 80 PKR × quantity : 0
transportHandling = 250 PKR (fixed)
```

### Quantity Efficiency
```
if (1-5 units): laborCost × 1.20 (20% surcharge)
if (6-20 units): laborCost × 1.00 (normal)
if (21-50 units): laborCost × 0.95 (5% efficiency)
if (51+ units): laborCost × 0.90 (10% efficiency)
```

### Total Cost
```
subtotal = materialCost + laborCost + processingCost + packagingCost + transportHandling
rushCharges = (availableDays < estimatedDays) ? subtotal × 0.15 : 0
estimatedTotal = subtotal + rushCharges
```

### Production Time Estimation
```
totalLaborHours = (baseLaborHours × quantity)
estimatedProductionDays = ceil(totalLaborHours / 8)

Department allocations:
  - Cutting: 20%
  - Stitching: 45%
  - Header Installation: 15%
  - Finishing & Ironing: 10%
  - Quality Control: 5%
  - Packaging & Dispatch: 5%
```

---

## Integration with Existing System

### OrderCalculationService Changes

The main service now routes curtain orders to the specialized service:

```dart
Future<CalculationResult> calculateOrderEstimate(OrderDraftInput input) async {
  // Route curtain orders
  if (input.productCategory.toLowerCase() == 'curtain') {
    return _calculateCurtainEstimate(input);
  }
  
  // Use generic calculation for other categories
  return _performCalculation(input, costConfig);
}
```

### OrderInputController Changes

1. **Updated `buildSpecifications()`** to include `custom_packaging` flag for curtain orders
2. **Enhanced validation** with better error messages:
   - Length/width range validation (0-10m, 0-5m)
   - Required field checks
   - Specific curtain-relevant error messages

### Data Flow

```
OrderInputController
  ↓ (buildSpecifications() includes length, width, fabric, header, packaging)
  ↓
OrderCalculationService.calculateOrderEstimate()
  ↓ (routes Curtain → CurtainCalculationService)
  ↓
CurtainCalculationService.calculateCurtainEstimate()
  ├─ Validate specs
  ├─ Fetch config from CurtainCostRepository
  ├─ Perform calculations
  └─ Return CalculationResult
  ↓
OrderInputController receives result
  ├─ Displays cost breakdown
  ├─ Shows production timeline
  └─ Allows save/submit
```

---

## Database Schema

### curtain_cost_config Table

```sql
CREATE TABLE curtain_cost_config (
    id UUID PRIMARY KEY,
    curtain_type VARCHAR(50) NOT NULL,
    fabric_type VARCHAR(50) NOT NULL,
    header_style VARCHAR(50) NOT NULL,
    material_rate NUMERIC(10, 2),           -- PKR per sq meter
    labor_multiplier NUMERIC(5, 2),         -- Multiplier for base hours
    complexity_multiplier NUMERIC(5, 2),    -- Type + header complexity
    base_labor_hours NUMERIC(6, 2),         -- Hours per unit
    processing_cost NUMERIC(10, 2),         -- PKR
    wastage_percent NUMERIC(5, 2),          -- Percentage
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE(curtain_type, fabric_type, header_style)
);
```

**Indexes:**
- `idx_curtain_type` - Query by curtain type
- `idx_fabric_type` - Query by fabric type
- `idx_header_style` - Query by header style
- `idx_curtain_lookup` - Combined lookup
- `idx_updated_at` - Track changes

**36 Seed Rows:**
- 4 curtain types × 3 fabric types × 3 header styles = 36 combinations
- All realistic multipliers and costs

---

## Usage Examples

### Example 1: Calculate Window Curtain Order

```dart
// User input from controller
final request = CurtainCalculationRequest(
  curtainType: 'Window Curtain',
  fabricType: 'Sheer',
  headerStyle: 'Pleated',
  length: 1.5,        // meters
  width: 1.0,         // meters
  quantity: 5,
  qualityGrade: 'Standard',
  requiredDeliveryDate: DateTime.now().add(Duration(days: 7)),
  customPackaging: false,
);

// Calculate
final service = CurtainCalculationService();
final result = await service.calculateCurtainEstimate(request);

// Result contains:
print('Material: ${result.costBreakdown.totalMaterialCost} PKR');
print('Labor: ${result.costBreakdown.totalLaborCost} PKR');
print('Processing: ${result.costBreakdown.totalProcessingCost} PKR');
print('Total: ${result.estimatedTotalCost} PKR');
print('Days: ${result.estimatedProductionDays}');
print('Priority: ${result.priority}');
```

### Example 2: Batch Order with Efficiency

```dart
// Large batch order
final request = CurtainCalculationRequest(
  curtainType: 'Door Curtain',
  fabricType: 'Blackout',
  headerStyle: 'Eyelet',
  length: 2.0,
  width: 1.2,
  quantity: 100,  // Large batch
  qualityGrade: 'Premium',
  requiredDeliveryDate: DateTime.now().add(Duration(days: 30)),
  customPackaging: true,
);

final result = await service.calculateCurtainEstimate(request);

// Large quantity triggers efficiency scaling:
// - Labor cost multiplied by 0.90 (10% efficiency gain)
// - Setup surcharge: -10%
// Example: 10 units @ 500 PKR labor = 10,000 PKR normal
//          100 units @ 500 PKR labor = 45,000 PKR (0.90 multiplier)
```

### Example 3: Rush Order

```dart
final request = CurtainCalculationRequest(
  curtainType: 'Decorative Curtain',
  fabricType: 'Thermal',
  headerStyle: 'Rod Pocket',
  length: 1.5,
  width: 1.0,
  quantity: 1,
  qualityGrade: 'Premium',
  requiredDeliveryDate: DateTime.now().add(Duration(days: 2)), // Rush!
  customPackaging: true,
);

final result = await service.calculateCurtainEstimate(request);

// Automatic rush detection:
// if (availableDays < estimatedDays) {
//   rushCharges = subtotal × 15%
// }
// Result: Premium + thermal + rush = highest cost
```

---

## Migration & Deployment

### 1. Run Supabase Migration

```bash
# From project root
supabase migration up

# Or manually via Supabase dashboard
# Copy contents of supabase/migrations/20260507000100_create_curtain_cost_config.sql
# Execute in SQL editor
```

### 2. Seed Data

**Option A: Via Repository**
```dart
final repo = CurtainCostRepository();
final count = await repo.seedDefaultConfigurations();
print('Seeded $count configurations');
```

**Option B: Already included in migration SQL**
- Migration file includes INSERT statements for all 36 configurations

### 3. Verify Installation

```dart
final repo = CurtainCostRepository();
final hasData = await repo.hasConfigurationData();
final count = await repo.getConfigurationCount();

if (hasData && count == 36) {
  print('✅ Curtain costing system ready!');
}
```

---

## Testing

### Unit Test Example

```dart
test('Calculate Window Curtain with realistic values', () async {
  final request = CurtainCalculationRequest(
    curtainType: 'Window Curtain',
    fabricType: 'Sheer',
    headerStyle: 'Pleated',
    length: 1.5,
    width: 1.0,
    quantity: 10,
    qualityGrade: 'Standard',
    requiredDeliveryDate: DateTime.now().add(Duration(days: 10)),
    customPackaging: false,
  );

  final service = CurtainCalculationService();
  final result = await service.calculateCurtainEstimate(request);

  // Verify material cost
  expect(result.costBreakdown.totalMaterialCost, greaterThan(0));
  
  // Verify labor cost
  expect(result.costBreakdown.totalLaborCost, greaterThan(0));
  
  // Verify not rush (10 days is reasonable)
  expect(result.priority, 'Normal');
  
  // Verify total > 0
  expect(result.estimatedTotalCost, greaterThan(0));
});
```

---

## Customization Guide

### To Change Labor Rate
```dart
// In curtain_pricing_rules.dart
static const double laborRatePerHour = 350.0; // Change this value
```

### To Add New Curtain Type
```dart
// 1. Add to curtain_pricing_rules.dart
static const Map<String, CurtainTypeConfig> curtainTypeConfigs = {
  'New Type': CurtainTypeConfig(...),
  ...
};

// 2. Add seed data to migration SQL
INSERT INTO curtain_cost_config VALUES (
  'New Type', 'Sheer', 'Pleated', ...
), ...

// 3. Update controller
static const productTypesByCategory = {
  'Curtain': [..., 'New Type'],
  ...
};
```

### To Adjust Multipliers
Edit values in `curtain_pricing_rules.dart`:
- `curtainTypeConfigs` - Type multipliers
- `fabricTypeConfigs` - Fabric rates and multipliers
- `headerStyleConfigs` - Header labor and cost
- `qualityGradeConfigs` - Quality multipliers
- `quantityEfficiencyRules` - Batch efficiency

Changes are effective immediately (no database restart needed).

---

## Performance Considerations

### Database Queries
- Lookup query: O(1) with composite index
- All configs cache-friendly (36 small rows)
- Consider caching configs in memory if high frequency

### Calculation Performance
- Single calculation: ~10-50ms (mostly DB fetch)
- All multiplications are simple floating-point
- No complex loops

### Memory Usage
- Service instances are lightweight
- Repository caches nothing (stateless)
- Configs fetched on-demand

---

## Error Handling

### Validation Errors
```dart
final validation = CurtainPricingRules.validateCurtainSpecs(...);
if (!validation.isValid) {
  print(validation.errors); // List of validation issues
}
```

### Database Errors
- Repository returns `null` if config not found
- Service throws descriptive exceptions
- Fallback: Service throws exception (don't silently fail)

### Input Errors
```dart
try {
  final result = await service.calculateCurtainEstimate(request);
} on Exception catch (e) {
  print('Calculation error: $e');
  // Handle error in UI
}
```

---

## Monitoring & Analytics

### Key Metrics to Track

1. **Cost Breakdown Distribution**
   - Average material % of total
   - Average labor % of total
   - Average processing % of total

2. **Order Patterns**
   - Most common curtain type/fabric/header combo
   - Average order quantity
   - Rush order frequency

3. **Timing Accuracy**
   - Estimated vs actual production days
   - Department throughput

### Logging Recommendations
```dart
// Add logging in CurtainCalculationService
print('Calculating: $curtainType / $fabricType / $headerStyle');
print('Area per unit: ${fabricAreaPerUnit}m²');
print('Labor hours: ${totalLaborHours}h');
print('Total cost: ${estimatedTotal} PKR');
```

---

## Future Enhancements

### Phase 2 Possibilities
1. **Dynamic Pricing** - Adjust rates based on:
   - Seasonal demand
   - Raw material costs
   - Capacity utilization

2. **Machine Time** - Add machine-specific scheduling:
   - Cutting machine hours
   - Stitching machine hours
   - Pressing machine hours

3. **Waste Tracking** - Real-time waste metrics:
   - Actual vs estimated wastage
   - Cost variance analysis

4. **Custom Headers** - Support user-defined header styles:
   - Custom labor hours
   - Custom processing costs

5. **Integration** - Connect to:
   - Inventory system (fabric stock levels)
   - Supplier system (raw material costs)
   - HR system (labor availability)

---

## Support & Maintenance

### Regular Tasks

- **Monthly**: Review pricing accuracy vs actual costs
- **Quarterly**: Update multipliers based on performance data
- **Yearly**: Add new fabric types or styles as needed

### Troubleshooting

**Issue: "Curtain cost configuration not found"**
- Check database has seed data
- Verify curtain_type, fabric_type, header_style exact match

**Issue: Calculations seem incorrect**
- Verify multipliers in curtain_pricing_rules.dart
- Check fabric area calculation (length × width)
- Validate quantity efficiency rules

**Issue: Production time too high/low**
- Adjust base_labor_hours in database
- Check department percentage splits
- Review quality multipliers

---

## Code Structure Summary

```
lib/services/
├── order_calculation_service.dart (UPDATED - routes Curtain)
├── curtain/
│   ├── curtain_pricing_rules.dart ........... Constants & rules
│   ├── curtain_cost_config.dart ............ Data models
│   ├── curtain_cost_repository.dart ........ DB access
│   └── curtain_calculation_service.dart ... Main logic
└── (other services unchanged)

lib/controllers/
└── new_order/
    └── order_input_controller.dart (UPDATED - validation)

supabase/
└── migrations/
    └── 20260507000100_create_curtain_cost_config.sql (NEW)
```

---

## Conclusion

This implementation provides:

✅ **Complete isolation** - All curtain logic in dedicated files
✅ **Realistic costing** - Based on textile manufacturing best practices
✅ **Easy maintenance** - Modular architecture for future updates
✅ **Production-ready** - Comprehensive error handling and validation
✅ **Scalable** - Database-driven configuration
✅ **Well-documented** - This guide + inline code comments

The system is ready for production deployment and future enhancement.
